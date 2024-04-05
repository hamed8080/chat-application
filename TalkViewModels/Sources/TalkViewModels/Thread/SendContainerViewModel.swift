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
    private let thread: Conversation
    public weak var threadVM: ThreadViewModel?
    public var threadId: Int { thread.id ?? -1 }
    private var textMessage: String
    private var cancelable: Set<AnyCancellable> = []
    public var canShowMute: Bool {
        (thread.type?.isChannelType == true) &&
        (thread.admin == false || thread.admin == nil) &&
        !isInEditMode
    }
    public var disableSend: Bool { thread.disableSend && isInEditMode == false && !canShowMute }
    public var showSendButton: Bool {
        !isTextEmpty(text: textMessage) ||
        threadVM?.attachmentsViewModel.attachments.count ?? 0 > 0 ||
        AppState.shared.appStateNavigationModel.forwardMessageRequest != nil
    }
    public var showCamera: Bool { isTextEmpty(text: textMessage) && isVideoRecordingSelected }
    public var showAudio: Bool { isTextEmpty(text: textMessage) && !isVideoRecordingSelected && isVoice }
    public var isVoice: Bool { threadVM?.attachmentsViewModel.attachments.count == 0 }
    public var showRecordingView: Bool { threadVM?.audioRecoderVM.isRecording == true || threadVM?.audioRecoderVM.recordingOutputPath != nil }
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    public private(set) var showActionButtons: Bool = false
    public private(set) var focusOnTextInput: Bool = false
    public private(set) var isVideoRecordingSelected = false
    public var isInEditMode: Bool { editMessage != nil }
    private var editMessage: Message?
    public var height: CGFloat = 0
    private var draft: String {
        get {
            UserDefaults.standard.string(forKey: "draft-\(threadId)") ?? ""
        }
        set {
            if newValue.isEmpty {
                UserDefaults.standard.removeObject(forKey: "draft-\(threadId)")
            } else {
                UserDefaults.standard.setValue(newValue, forKey: "draft-\(threadId)")
            }
        }
    }

    private var isDraft: Bool { !draft.isEmpty }

    public static func == (lhs: SendContainerViewModel, rhs: SendContainerViewModel) -> Bool {
        rhs.thread.id == lhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }

    public init(thread: Conversation) {
        textMessage = UserDefaults.standard.string(forKey: "draft-\(thread.id ?? 0)") ?? ""
        self.thread = thread
    }

    private func onTextMessageChanged(_ newValue: String) {
        if Language.isRTL && newValue.first != "\u{200f}" {
            textMessage = "\u{200f}\(newValue)"
        }
        threadVM?.mentionListPickerViewModel.text = newValue
        threadVM?.sendStartTyping(newValue)
        let isRTLChar = newValue.count == 1 && newValue.first == "\u{200f}"
        if !isTextEmpty(text: newValue) && !isRTLChar {
            draft = newValue
        } else {
            draft = ""
        }
    }

    public func clear() {
        textMessage = ""
        editMessage = nil
        animateObjectWillChange()
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

    public func setText(newValue: String) {
        textMessage = newValue
        onTextMessageChanged(textMessage)
        animateObjectWillChange()
    }

    public func setEditMessage(message: Message?) {
        self.editMessage = message
        animateObjectWillChange()
    }

    public func getEditMessage() -> Message? {
        return editMessage
    }

    public func toggleActionButtons() {
        showActionButtons.toggle()
        animateObjectWillChange()
    }

    public func setFocusOnTextView(focus: Bool = false) {
        focusOnTextInput = focus
        animateObjectWillChange()
    }

    public func toggleVideorecording() {
        isVideoRecordingSelected.toggle()
        animateObjectWillChange()
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
