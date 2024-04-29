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
    private weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    private var threadId: Int { thread?.id ?? -1 }
    @Published public var text: String = ""
    @Published public private(set) var mentionList: ContiguousArray<Participant> = .init()
    private var cancelable: Set<AnyCancellable> = []
    private var searchText: String? = nil
    @MainActor public var lazyList = LazyListViewModel()

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        $text
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { newValue in
                Task { [weak self] in
                    await self?.searchForParticipantInMentioning(newValue)
                }
            }
            .store(in: &cancelable)

        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { event in
                Task { [weak self] in
                    await self?.onParticipantsEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    @MainActor
    public func searchForParticipantInMentioning(_ text: String) async {
        if thread?.group == false || thread?.group == nil { return }
        /// remove the hidden RTL character for forcing the UITextView to write from right to left.
        let text = text.replacingOccurrences(of: "\u{200f}", with: "")
        if text.last == "@" {
            // Fetch some data to show if the user typed an @.
            searchText = nil
            lazyList.reset()
            await getParticipants()
        } else if text.matches(char: "@")?.last != nil, text.split(separator: " ").last?.first == "@", text.last != " " {
            searchText = text.split(separator: " ").last?.replacingOccurrences(of: "@", with: "")
            lazyList.reset()
            await getParticipants()
        } else {
            let mentionListWasFill = mentionList.count > 0
            mentionList = []
            if mentionListWasFill {
                animateObjectWillChange()
            }
        }
    }

    @MainActor
    func onParticipants(_ response: ChatResponse<[Participant]>) async {
        if !response.cache, response.pop(prepend: "MentionParticipants") != nil, let participants = response.result {
            if lazyList.offset == 0 {
                self.mentionList.removeAll()
                self.mentionList = .init(participants)
            } else {
                lazyList.setHasNext(response.hasNext)
                self.mentionList.append(contentsOf: participants)
            }
            lazyList.setLoading(false)
            mentionList.removeAll(where: {$0.id == AppState.shared.user?.id})
            animateObjectWillChange()
        }
    }

    public func onParticipantsEvent(_ event: ParticipantEventTypes) async {
        switch event {
        case .participants(let response):
            await onParticipants(response)
        default:
            break
        }
    }

    @MainActor
    private func getParticipants() async {
        lazyList.setLoading(true)
        let count = lazyList.count
        let offset = lazyList.offset
        let req = ThreadParticipantRequest(threadId: threadId, offset: offset, count: count, name: searchText)
        RequestsManager.shared.append(prepend: "MentionParticipants", value: req)
        ChatManager.activeInstance?.conversation.participant.get(req)
    }

    public func loadMore() async {
        if await !lazyList.canLoadMore() { return }
        await lazyList.prepareForLoadMore()
        await getParticipants()
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
