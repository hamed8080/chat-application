//
//  MessageRowViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 3/9/23.
//

import Chat
import MapKit
import SwiftUI
import TalkExtensions
import ChatModels
import Combine
import TalkModels
import NaturalLanguage
import ChatDTO

public final class MessageRowViewModel: ObservableObject {
    public var isCalculated = false
    public var isEnglish = true
    public var widthOfRow: CGFloat = 128
    public var markdownTitle = AttributedString()
    public var calculatedMaxAndMinWidth: CGFloat = 128
    public var addressDetail: String?
    public var timeString: String = ""
    public var fileSizeString: String?
    public static var avatarSize: CGFloat = 24
    public var downloadFileVM: DownloadFileViewModel?
    public weak var threadVM: ThreadViewModel?
    private var cancelableSet = Set<AnyCancellable>()
    public let message: Message
    public var isInSelectMode: Bool = false
    public var isMe: Bool
    public var isHighlited: Bool = false
    public var highlightTimer: Timer?
    public var isSelected = false
    public init(message: Message, viewModel: ThreadViewModel) {
        self.message = message
        if message.isFileType {
            self.downloadFileVM = DownloadFileViewModel(message: message)
        }
        self.threadVM = viewModel
        self.isMe = message.isMe(currentUserId: AppState.shared.user?.id)
    }

    @MainActor
    public func calculate() {
        if isCalculated { return }
        isCalculated = true
        NotificationCenter.default.publisher(for: .windowMode)
            .sink { [weak self] newValue in
                self?.recalculateWithAnimation()
            }
            .store(in: &cancelableSet)

        NotificationCenter.default.publisher(for: .message)
            .compactMap{ $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelableSet)

        NotificationCenter.default.publisher(for: Notification.Name("UPDATE_OLDER_SEENS_LOCALLY"))
            .compactMap {$0.object as? MessageResponse}
            .sink { [weak self] newValue in
                self?.message.delivered = true
                self?.message.seen = true
                self?.updateWithAnimation()
            }
            .store(in: &cancelableSet)

        NotificationCenter.default.publisher(for: Notification.Name("HIGHLIGHT"))
            .compactMap {$0.object as? Int}
            .sink { [weak self] newValue in
                if let messageId = self?.message.id, messageId == newValue {
                    self?.isHighlited = true
                    self?.updateWithAnimation()
                    self?.startHighlightTimer()
                }
            }
            .store(in: &cancelableSet)
        threadVM?.$isInEditMode.sink { [weak self] newValue in
            /// Use if newValue != isInSelectMode to assure the newValue has arrived and all message rows will not get refreshed.
            if newValue != self?.isInSelectMode {
                self?.isInSelectMode = newValue
                self?.updateWithAnimation()
            }
        }
        .store(in: &cancelableSet)
        Task.detached(priority: .background) { [weak self] in
            await self?.performaCalculation()
        }
    }

    private func startHighlightTimer() {
        highlightTimer?.invalidate()
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.isHighlited = false
            self?.updateWithAnimation()
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        /// Update the message after message has sent to server and the chat server respond wtih MessageVOTypes.Message we should update ui for upload messages.
        if case let .new(response) = event, message.uniqueId == response.result?.uniqueId, let message = response.result {
            self.message.updateMessage(message: message)
            recalculateWithAnimation()
        }
        if case let .edited(response) = event, message.id == response.result?.id {
            message.message = response.result?.message
            message.time = response.result?.time
            message.edited = true
            recalculateWithAnimation()
        }

        if case let .seen(response) = event, message.id == response.result?.messageId {
            message.delivered = true
            message.seen = true
            updateWithAnimation()
        }

        if case let .sent(response) = event, message.id == response.result?.messageId {
            message.id = response.result?.messageId
            message.time = response.result?.messageTime
            updateWithAnimation()
        }

        if case let .delivered(response) = event, message.id == response.result?.messageId {
            message.delivered = true
            updateWithAnimation()
        }

        if case let .pin(response) = event, message.id == response.result?.messageId {
            message.pinned = true
            message.pinTime = response.result?.time
            recalculateWithAnimation()
        }

        if case let .unpin(response) = event, message.id == response.result?.messageId {
            message.pinned = false
            message.pinTime = nil
            recalculateWithAnimation()
        }
    }

    private func updateWithAnimation() {
        withAnimation(.easeInOut) {
            self.objectWillChange.send()
        }
    }

    private func recalculateWithAnimation(){
        Task.detached(priority: .background) { [weak self] in
            await self?.performaCalculation(animation: .easeInOut)
        }
    }

    private func performaCalculation(animation: Animation? = nil) async {
        let message = message
        let isEnglish = message.message?.naturalTextAlignment == .leading
        let widthOfRow = self.calculateWidthOfMessage()
        let markdownTitle = message.markdownTitle
        let addressDetail = await message.addressDetail
        let timeString = message.time?.date.timeAgoSinceDateCondense ?? ""
        let fileSizeString = message.fileMetaData?.file?.size?.toSizeString
        await MainActor.run {
            self.addressDetail = addressDetail ?? ""
            self.isEnglish = isEnglish
            self.widthOfRow = widthOfRow
            self.markdownTitle = markdownTitle
            self.timeString = timeString
            self.fileSizeString = fileSizeString
            withAnimation(animation?.speed(0.8)) {
                self.objectWillChange.send()
            }
        }
    }

    public func footerWidth() -> CGFloat {
        let timeWidth = message.time?.date.timeAgoSinceDateCondense?.widthOfString(usingFont: UIFont.systemFont(ofSize: 24)) ?? 0
        let fileSizeWidth = fileSizeString?.widthOfString(usingFont: UIFont.systemFont(ofSize: 24)) ?? 0
        let statusWidth: CGFloat = isMe ? 14 : 0
        let isEditedWidth: CGFloat = message.edited ?? false ? 24 : 0
        let isPinnedWidth: CGFloat = message.id == threadVM?.thread.pinMessage?.id && threadVM?.thread.pinMessage != nil ? 24 : 0
        let messageStatusIconWidth: CGFloat = 24
        return timeWidth + fileSizeWidth + statusWidth + isEditedWidth + messageStatusIconWidth + isPinnedWidth
    }

    public var maxAllowedWidth: CGFloat {
        let modes: [WindowMode] = [.iPhone, .ipadOneThirdSplitView, .ipadSlideOver]
        let isInCompactMode = modes.contains(AppState.shared.windowMode)
        let max: CGFloat = isInCompactMode ? 320 : 480
        return max
    }

    public func minWidth() -> CGFloat {
        let hasReplyMessage = message.replyInfo != nil
        return message.isUnsentMessage ? 148 : message.isFileType ? 164 : hasReplyMessage ? 246 : 128
    }

    public func headerWidth() -> CGFloat {
        let spacing: CGFloat = 8
        let padding: CGFloat = 16
        return (message.participant?.name?.widthOfString(usingFont: .systemFont(ofSize: 22)) ?? 0) + MessageRowViewModel.avatarSize + spacing + padding
    }

    public func unsentFileWidth() -> CGFloat {
        if message is UnSentMessageProtocol {
            let cancelButtonWidth: CGFloat = 64
            let resendButtonWidth: CGFloat = 69
            let padding: CGFloat = 16
            let controlsSize = cancelButtonWidth + resendButtonWidth + padding
            let fileNameWidth = "\(message.fileName ?? "").\(message.fileExtension ?? "")".widthOfString(usingFont: .systemFont(ofSize: 12)) + padding
            let width = max(controlsSize, fileNameWidth)
            return width
        }
        return 0
    }

    public func calculateWidthOfMessage() -> CGFloat {
        let imageWidth: CGFloat = CGFloat(message.fileMetaData?.file?.actualWidth ?? 0)
        let messageWidth = message.messageTitle.widthOfString(usingFont: UIFont.systemFont(ofSize: 16)) + 16
        let headerWidth = headerWidth()
        let footerWidth = footerWidth()
        let videoWidth: CGFloat = message.isVideo ? 320 : 0
        let uploadFileProgressWidth: CGFloat = message.isUploadMessage == true ? 128 : 0
        let unsentFileWidth = unsentFileWidth()
        let contentWidth = [imageWidth, messageWidth, headerWidth, footerWidth, uploadFileProgressWidth, unsentFileWidth, videoWidth].max() ?? 0
        let calculatedWidth: CGFloat = min(contentWidth, maxAllowedWidth)
        return calculatedWidth
    }

    deinit {
        downloadFileVM?.cancelObservers()
        downloadFileVM = nil
#if Debug
        print("Deinit get called for message: \(message.message ?? "") and message isFileTye:\(message.isFileType) and id is: \(message.id ?? 0)")
#endif
    }
}
