//
//  MentionListPickerViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import ChatCore
import ChatModels
import ChatDTO
import Combine

public final class MentionListPickerViewModel: ObservableObject {
    private let thread: Conversation
    private var threadId: Int { thread.id ?? -1 }
    @Published public var text: String = ""
    @Published public private(set) var mentionList: ContiguousArray<Participant> = .init()
    private var cancelable: Set<AnyCancellable> = []

    public static func == (lhs: MentionListPickerViewModel, rhs: MentionListPickerViewModel) -> Bool {
        rhs.thread.id == lhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }

    public init(thread: Conversation) {
        self.thread = thread
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        $text
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
            self?.searchForParticipantInMentioning(newValue)
        }
        .store(in: &cancelable)

        NotificationCenter.default.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] event in
                self?.onParticipantsEvent(event)
            }
            .store(in: &cancelable)
    }

    public func searchForParticipantInMentioning(_ text: String) {
        if thread.group == false || thread.group == nil { return }
        /// remove the hidden RTL character for forcing the UITextView to write from right to left.
        let text = text.replacingOccurrences(of: "\u{200f}", with: "")
        if text.last == "@" {
            // Fetch some data to show if the user typed an @.
            let req = ThreadParticipantRequest(threadId: threadId, count: 15)
            RequestsManager.shared.append(prepend: "MentionParticipants", value: req)
            ChatManager.activeInstance?.conversation.participant.get(req)
        } else if text.matches(char: "@")?.last != nil, text.split(separator: " ").last?.first == "@", text.last != " " {
            let rangeText = text.split(separator: " ").last?.replacingOccurrences(of: "@", with: "")
            let req = ThreadParticipantRequest(threadId: threadId, count: 15, name: rangeText)
            RequestsManager.shared.append(prepend: "MentionParticipants", value: req)
            ChatManager.activeInstance?.conversation.participant.get(req)
        } else {
            let mentionListWasFill = mentionList.count > 0
            mentionList = []
            if mentionListWasFill {
                animateObjectWillChange()
            }
        }
    }

    func onParticipants(_ response: ChatResponse<[Participant]>) {
        if response.value(prepend: "MentionParticipants") != nil, !response.cache, let participants = response.result {
            self.mentionList.removeAll()
            self.mentionList = .init(participants)
            mentionList.removeAll(where: {$0.id == AppState.shared.user?.id})
            animateObjectWillChange()
        }
    }

    public func onParticipantsEvent(_ event: ParticipantEventTypes) {
        switch event {
        case .participants(let response):
            onParticipants(response)
        default:
            break
        }
    }
}
