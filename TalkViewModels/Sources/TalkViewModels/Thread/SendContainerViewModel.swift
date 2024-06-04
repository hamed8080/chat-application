//
//  SendContainerViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine
import TalkModels

public final class SendContainerViewModel {
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init() }
    public var threadId: Int { thread.id ?? -1 }
    private var textMessage: String = ""
    private var cancelable: Set<AnyCancellable> = []
    public var isInEditMode: Bool = false
    public var canShowMute: Bool {
        (thread.type?.isChannelType == true) &&
        (thread.admin == false || thread.admin == nil) &&
        !isInEditMode
    }
    public var disableSend: Bool { thread.disableSend && isInEditMode == false && !canShowMute }
    public var showSendButton: Bool {
        !isTextEmpty() ||
        viewModel?.attachmentsViewModel.attachments.count ?? 0 > 0 ||
        AppState.shared.appStateNavigationModel.forwardMessageRequest != nil
    }
    public var showCamera: Bool { isTextEmpty() && isVideoRecordingSelected }
    public var showAudio: Bool { isTextEmpty() && !isVideoRecordingSelected && isVoice }
    public var isVoice: Bool { viewModel?.attachmentsViewModel.attachments.count == 0 }
    public var showRecordingView: Bool { viewModel?.audioRecoderVM.isRecording == true || viewModel?.audioRecoderVM.recordingOutputPath != nil }
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    public private(set) var showActionButtons: Bool = false
    public private(set) var focusOnTextInput: Bool = false
    public private(set) var isVideoRecordingSelected = false
    private var editMessage: Message?
    public var height: CGFloat = 0
    private let draftManager = DraftManager.shared
    public var onTextChanged: ((String?) -> Void)?

    public init() {}

    public static func == (lhs: SendContainerViewModel, rhs: SendContainerViewModel) -> Bool {
        rhs.thread.id == lhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        let contactId = AppState.shared.appStateNavigationModel.userToCreateThread?.contactId ?? -1
        let textMessage = draftManager.get(threadId: threadId) ?? draftManager.get(contactId: contactId) ?? ""
        setText(newValue: textMessage)
        editMessage = getDraftEditMessage()
    }

    private func onTextMessageChanged(_ newValue: String) {
        if Language.isRTL && textMessage.first != "\u{200f}" {
            setText(newValue: "\u{200f}\(textMessage)")
        }
        viewModel?.mentionListPickerViewModel.text = textMessage
        viewModel?.sendStartTyping(textMessage)
        let isRTLChar = textMessage.count == 1 && textMessage.first == "\u{200f}"
        if !isTextEmpty() && !isRTLChar {
            setDraft(newText: newValue)
        } else {
            setDraft(newText: "")
        }
    }

    public func clear() {
        setText(newValue: "")
        editMessage = nil
        isInEditMode = false
    }

    public func isTextEmpty() -> Bool {
        let sanitizedText = textMessage.replacingOccurrences(of: "\u{200f}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitizedText.isEmpty
    }

    public func addMention(_ participant: Participant) {
        let userName = (participant.username ?? "")
        var text = textMessage
        if let lastIndex = text.lastIndex(of: "@") {
            text.removeSubrange(lastIndex..<text.endIndex)
        }
        setText(newValue: "\(text)@\(userName) ") // To hide participants dialog
    }

    public func getText() -> String {
        textMessage.replacingOccurrences(of: "\u{200f}", with: "")
    }

    public func setText(newValue: String) {
        textMessage = newValue
        onTextMessageChanged(newValue)
        onTextChanged?(getText())
    }

    public func setEditMessage(message: Message?) {
        self.editMessage = message
        isInEditMode = message != nil
    }

    public func getEditMessage() -> Message? {
        return editMessage
    }

    public func toggleActionButtons() {
        showActionButtons.toggle()
        viewModel?.delegate?.onAttchmentButtonsMenu(show: showActionButtons)
    }

    public func setFocusOnTextView(focus: Bool = false) {
        focusOnTextInput = focus
    }

    public func toggleVideorecording() {
        isVideoRecordingSelected.toggle()
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

    /// If we are in edit mode drafts will not be changed.
    private func onEditMessageChanged(_ editMessage: Message?) {
        if editMessage != nil {
            let text = editMessage?.message ?? ""

            /// set edit message draft for the thread
            setEditMessageDraft(editMessage)

            /// It will trigger onTextMessageChanged method
            if draftManager.get(threadId: threadId) == nil {
                setText(newValue: text)
            }
        } else {
            setEditMessageDraft(nil)
        }
    }

    private func setEditMessageDraft(_ editMessage: Message?) {
        draftManager.setEditMessageDraft(editMessage, threadId: threadId)
    }

    private func getDraftEditMessage() -> Message? {
        draftManager.editMessageText(threadId: threadId)
    }

    private var isSimulated: Bool { threadId == -1 || threadId == LocalId.emptyThread.rawValue }

    public func setAttachmentButtonsVisibility(show: Bool) {
        showActionButtons = show
    }
}
