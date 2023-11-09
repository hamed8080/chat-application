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
    public var maxWidth: CGFloat?
    public var markdownTitle = AttributedString()
    public var addressDetail: String?
    public var timeString: String = ""
    public static var avatarSize: CGFloat = 34
    public var downloadFileVM: DownloadFileViewModel?
    public weak var threadVM: ThreadViewModel?
    private var cancelableSet = Set<AnyCancellable>()
    public let message: Message
    public var isInSelectMode: Bool = false
    public var isMe: Bool
    public var isHighlited: Bool = false
    public var highlightTimer: Timer?
    public var isSelected = false
    public var requests: [String: Any] = [:]
    public var showReactionsOverlay = false
    public var isNextMessageTheSameUser: Bool = false
    public var canShowIconFile: Bool = false
    public var canEdit: Bool { (message.editable == true && isMe) || (message.editable == true && threadVM?.thread.admin == true) }
    public var canDelete: Bool { (message.deletable == true && isMe) || (message.deletable == true && threadVM?.thread.admin == true) }
    public var avatarImageLoader: ImageLoaderViewModel? {
        if let image = message.participant?.image, let imageLoaderVM = threadVM?.threadsViewModel?.avatars(for: image) {
            return imageLoaderVM
        } else {
            return nil
        }
    }

    public init(message: Message, viewModel: ThreadViewModel) {
        self.message = message
        if message.isFileType {
            self.downloadFileVM = DownloadFileViewModel(message: message)
        }
        self.threadVM = viewModel
        self.isMe = message.isMe(currentUserId: AppState.shared.user?.id)
        setupObservers()
        maxWidth = message.isImage ? maxAllowedWidth : nil
        canShowIconFile = message.replyInfo?.messageType != .text && message.replyInfo?.message.isEmptyOrNil == true && message.replyInfo?.deleted == false
    }

    func setupObservers() {
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
    }

    @MainActor
    public func calculate() {
        if isCalculated { return }
        isCalculated = true
        recalculateWithAnimation()
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

    private func recalculateWithAnimation() {
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.performaCalculation(animation: .easeInOut)
        }
    }

    private func performaCalculation(animation: Animation? = nil) async {
        isNextMessageTheSameUser = threadVM?.thread.group == true && (threadVM?.isNextSameUser(message: message) == true) && message.participant != nil
        let isEnglish = message.message?.naturalTextAlignment == .leading
        let maxWidth = self.calculateMaxWidth()
        let markdownTitle = message.markdownTitle
        let addressDetail = await message.addressDetail
        let timeString = message.time?.date.localFormattedTime ?? ""
        await MainActor.run {
            self.addressDetail = addressDetail
            self.isEnglish = isEnglish
            self.maxWidth = maxWidth
            self.markdownTitle = markdownTitle
            self.timeString = timeString
            withAnimation(.easeInOut) {
                self.objectWillChange.send()
            }
        }
    }

    public var maxAllowedWidth: CGFloat {
        let modes: [WindowMode] = [.iPhone, .ipadOneThirdSplitView, .ipadSlideOver]
        let isInCompactMode = modes.contains(AppState.shared.windowMode)
        let max: CGFloat = isInCompactMode ? 320 : 480
        return max
    }

    static let replyFont = UIFont(name: "IRANSansX", size: 11)
    static let messageFont = UIFont(name: "IRANSansX", size: 14)
    public func calculateMaxWidth() -> CGFloat? {
        let replyWidth = message.replyInfo?.message?.widthOfString(usingFont: MessageRowViewModel.replyFont ?? .systemFont(ofSize: 10)) ?? 0
        let messageWidth = message.message?.widthOfString(usingFont: MessageRowViewModel.messageFont ?? .systemFont(ofSize: 13)) ?? 0
        let imageWidth = CGFloat(message.fileMetaData?.file?.actualWidth ?? 0)
        if replyWidth > messageWidth && replyWidth > maxAllowedWidth {
            return maxAllowedWidth
        } else if replyWidth > messageWidth && replyWidth < maxAllowedWidth {
            return imageWidth > maxAllowedWidth ? maxAllowedWidth : nil
        } else if messageWidth > maxAllowedWidth {
            return maxAllowedWidth
        } else if message.isImage {
            if imageWidth > maxAllowedWidth {
                return maxAllowedWidth
            } else {
                return imageWidth
            }
        } else {
            return nil
        }
    }

    deinit {
        downloadFileVM?.cancelObservers()
        downloadFileVM = nil
#if Debug
        print("Deinit get called for message: \(message.message ?? "") and message isFileTye:\(message.isFileType) and id is: \(message.id ?? 0)")
#endif
    }
}
