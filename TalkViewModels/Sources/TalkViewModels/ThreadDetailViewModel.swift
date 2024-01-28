//
//  ThreadDetailViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import ChatDTO
import TalkModels
import ChatCore
import ChatModels
import TalkExtensions

public final class ThreadDetailViewModel: ObservableObject, Hashable {
    public static func == (lhs: ThreadDetailViewModel, rhs: ThreadDetailViewModel) -> Bool {
        lhs.thread?.id == rhs.thread?.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread?.id)
    }

    private(set) var cancelable: Set<AnyCancellable> = []
    public weak var thread: Conversation?
    public weak var threadVM: ThreadViewModel?
    public var searchText: String = ""
    @Published public var isInEditMode = false
    @Published public var dismiss = false
    @Published public var isLoading = false
    public var isGroup: Bool { thread?.group == true }
    public var canShowEditConversationButton: Bool { thread?.group == true && thread?.admin == true && thread?.type != .selfThread }
    public var participantDetailViewModel: ParticipantDetailViewModel?
    public lazy var editConversationViewModel: EditConversationViewModel? = {
        let vm = EditConversationViewModel(threadVM: threadVM)
        return vm
    }()

    public init() {}

    public func setup(thread: Conversation? = nil, threadVM: ThreadViewModel? = nil, participant: Participant? = nil) {
        clear()
        self.thread = thread
        self.threadVM = threadVM
        let threadP2PParticipant = AppState.shared.appStateNavigationModel.participantToCreate
        if let participant = participant ?? threadP2PParticipant {
            self.participantDetailViewModel = ParticipantDetailViewModel(participant: participant)
        } else if thread?.group == false, let partner = threadVM?.participantsViewModel.participants.first(where: {$0.auditor == false && $0.id != AppState.shared.user?.id}) {
            self.participantDetailViewModel = ParticipantDetailViewModel(participant: partner)
        }
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        participantDetailViewModel?.objectWillChange.sink { [weak self] _ in
            self?.animateObjectWillChange()
        }
        .store(in: &cancelable)
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .mute(let response):
            onMuteChanged(response)
        case .unmute(let response):
            onUnMuteChanged(response)
        case .deleted(let response):
            onDeleteThread(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        case .updatedInfo(let response):
            onUpdateThreadInfo(response)
        default:
            break
        }
    }

    public func toggleMute() {
        guard let threadId = thread?.id else { return }
        if thread?.mute ?? false == false {
            mute(threadId)
        } else {
            unmute(threadId)
        }
    }

    public func mute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.mute(req)
    }

    public func unmute(_ threadId: Int) {
        let req = GeneralSubjectIdRequest(subjectId: threadId)
        RequestsManager.shared.append(value: req)
        ChatManager.activeInstance?.conversation.unmute(req)
    }

    public func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = true
            animateObjectWillChange()
        }
    }

    public func onUnMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread?.mute = false
            animateObjectWillChange()
        }
    }

    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if response.subjectId == thread?.id {
            dismiss = true
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if response.result == thread?.id {
            dismiss = true
        }
    }

    private func onUpdateThreadInfo(_ response: ChatResponse<Conversation>) {
        if let updated = response.result {
            /// In the update thread info, the image property is nil and the metadata link is been filled by the server.
            /// So to update the UI properly we have to set it to link.
            if updated.image == nil, let metadatImagelink = updated.metaData?.file?.link {
                thread?.image = metadatImagelink
            }
            animateObjectWillChange()
        }
    }

    public func clear() {
        cancelObservers()
        thread = nil
        threadVM = nil
        searchText = ""
        isInEditMode = false
        dismiss = false
        isLoading = false
        participantDetailViewModel = nil
        editConversationViewModel = nil
    }

    public func cancelObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
        participantDetailViewModel?.cancelObservers()
    }

    deinit {
        print("deinit ThreadDetailViewModel")
    }
}
