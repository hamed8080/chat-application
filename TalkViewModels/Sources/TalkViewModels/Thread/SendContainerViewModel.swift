//
//  SendContainerViewModel.swift
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
import TalkModels

public final class SendContainerViewModel: ObservableObject {
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init() }
    public var threadId: Int { thread.id ?? -1 }
    @Published public var textMessage: String = ""
    private var cancelable: Set<AnyCancellable> = []
    public var canShowMute: Bool {
        (thread.type?.isChannelType == true) &&
        (thread.admin == false || thread.admin == nil) &&
        !isInEditMode
    }
    public var disableSend: Bool { thread.disableSend && isInEditMode == false && !canShowMute }
    public var showSendButton: Bool {
        !isTextEmpty(text: textMessage) ||
        viewModel?.attachmentsViewModel.attachments.count ?? 0 > 0 ||
        AppState.shared.appStateNavigationModel.forwardMessageRequest != nil
    }
    public var showCamera: Bool { isTextEmpty(text: textMessage) && isVideoRecordingSelected }
    public var showAudio: Bool { isTextEmpty(text: textMessage) && !isVideoRecordingSelected && isVoice }
    public var isVoice: Bool { viewModel?.attachmentsViewModel.attachments.count == 0 }
    public var showRecordingView: Bool { viewModel?.audioRecoderVM.isRecording == true || viewModel?.audioRecoderVM.recordingOutputPath != nil }
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    @Published public var showActionButtons: Bool = false
    public var focusOnTextInput: Bool = false
    @Published public var isVideoRecordingSelected = false
    @Published public var isInEditMode: Bool = false
    @Published public var editMessage: Message?
    public var height: CGFloat = 0
    private let draftManager = DraftManager.shared

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        let contactId = AppState.shared.appStateNavigationModel.userToCreateThread?.contactId ?? -1
        textMessage = draftManager.get(threadId: threadId) ?? draftManager.get(contactId: contactId) ?? ""
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        $textMessage
            .sink { [weak self] newValue in
                self?.onTextMessageChanged(newValue)
            }
            .store(in: &cancelable)
        
        $editMessage
            .sink { [weak self] editMessage in
                if editMessage != nil, self?.isDraft() == false {
                    self?.onTextMessageChanged(editMessage?.message ?? "")
                }
            }
            .store(in: &cancelable)
    }

    private func onTextMessageChanged(_ newValue: String) {
        if Language.isRTL && newValue.first != "\u{200f}" {
            textMessage = "\u{200f}\(newValue)"
        }
        viewModel?.mentionListPickerViewModel.text = newValue
        viewModel?.sendStartTyping(newValue)
        let isRTLChar = newValue.count == 1 && newValue.first == "\u{200f}"
        if !isTextEmpty(text: newValue) && !isRTLChar {
            setDraft(newText: newValue)
        } else {
            setDraft(newText: "")
        }
    }

    public func clear() {
        textMessage = ""
        editMessage = nil
        isInEditMode = false
        viewModel?.animateObjectWillChange()
    }

    private func isTextEmpty(text: String) -> Bool {
        let sanitizedText = text.replacingOccurrences(of: "\u{200f}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitizedText.isEmpty
    }

    public func addMention(_ participant: Participant) {
        let userName = (participant.username ?? "")
        var text = textMessage
        if let lastIndex = text.lastIndex(of: "@") {
            text.removeSubrange(lastIndex..<text.endIndex)
        }
        textMessage = "\(text)@\(userName) " // To hide participants dialog
    }

    public func getText() -> String {
        textMessage.replacingOccurrences(of: "\u{200f}", with: "")
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }

    public func setDraft(newText: String) {
        if !isSimulated {
            draftManager.set(draftValue: newText, threadId: threadId)
        } else if let contactId = AppState.shared.appStateNavigationModel.userToCreateThread?.contactId {
            draftManager.set(draftValue: newText, contactId: contactId)
        }
    }

    public func isDraft() -> Bool {
        var isDraft = false
        if !isSimulated {
            isDraft = draftManager.get(threadId: threadId).isEmptyOrNil
        } else if let contactId = AppState.shared.appStateNavigationModel.userToCreateThread?.contactId {
            isDraft = draftManager.get(contactId: contactId).isEmptyOrNil
        }
        return isDraft
    }

    private var isSimulated: Bool { threadId == -1 || threadId == LocalId.emptyThread.rawValue }
}
