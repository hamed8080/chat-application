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
    @Published public var textMessage: String
    private var cancelable: Set<AnyCancellable> = []
    public var canShowMute: Bool { (thread.type == .channel || thread.type == .channelGroup) && (thread.admin == false || thread.admin == nil) && !isInEditMode }
    public var disableSend: Bool { thread.disableSend && isInEditMode == false && !canShowMute }
    public var showSendButton: Bool {
        !textMessage.isEmpty || threadVM?.attachmentsViewModel.attachments.count ?? 0 > 0 || AppState.shared.appStateNavigationModel.forwardMessageRequest != nil
    }
    public var showCamera: Bool { textMessage.isEmpty && isVideoRecordingSelected }
    public var showAudio: Bool { textMessage.isEmpty && !isVideoRecordingSelected && isVoice }
    public var isVoice: Bool { threadVM?.attachmentsViewModel.attachments.count == 0 }
    public var showRecordingView: Bool { threadVM?.audioRecoderVM.isRecording == true || threadVM?.audioRecoderVM.recordingOutputPath != nil }
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    @Published public var showActionButtons: Bool = false
    public var focusOnTextInput: Bool = false
    @Published public var isVideoRecordingSelected = false
    @Published public var isInEditMode: Bool = false
    @Published public var editMessage: Message?
    public var height: CGFloat = 0

    public static func == (lhs: SendContainerViewModel, rhs: SendContainerViewModel) -> Bool {
        rhs.thread.id == lhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }

    public init(thread: Conversation) {
        textMessage = UserDefaults.standard.string(forKey: "draft-\(thread.id ?? 0)") ?? ""
        self.thread = thread
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        $textMessage.sink { [weak self] newValue in
            self?.onTextMessageChanged(newValue)
        }
        .store(in: &cancelable)
    }

    private func onTextMessageChanged(_ newValue: String) {
        threadVM?.mentionListPickerViewModel.text = newValue
        let isRTLChar = newValue.count == 1 && newValue.first == "\u{200f}"
        if !newValue.isEmpty && !isRTLChar {
            UserDefaults.standard.setValue(newValue, forKey: "draft-\(threadId)")
        } else {
            UserDefaults.standard.removeObject(forKey: "draft-\(threadId)")
        }
    }

    public func clear() {
        textMessage = ""
    }

}
