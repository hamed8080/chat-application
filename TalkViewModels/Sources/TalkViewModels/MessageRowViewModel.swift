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
import OSLog
import ChatCore

public final class MessageReactionsViewModel: ObservableObject {
    public var message: Message? { viewModel?.message }
    public weak var viewModel: MessageRowViewModel?
    public var reactionCountList: ContiguousArray<ReactionCount> = []
    private var inMemoryReaction: InMemoryReactionProtocol? { ChatManager.activeInstance?.reaction.inMemoryReaction }
    public var currentUserReaction: Reaction?
    private var cancelableSet = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    func setupObservers() {
        NotificationCenter.default.publisher(for: .reactionMessageUpdated)
            .sink { notification in
                if notification.object as? Int == self.message?.id {
                    Task {
                        try? await Task.sleep(for: .seconds(0.1))
                        await self.setReactionList()
                    }
                }
            }
            .store(in: &cancelableSet)
    }

    func setReactionList() async {
        if let reactionCountList = inMemoryReaction?.summary(for: message?.id ?? -1) {
            self.reactionCountList = .init(reactionCountList)
            currentUserReaction = ChatManager.activeInstance?.reaction.inMemoryReaction.currentReaction(message?.id ?? -1)
            await MainActor.run {
                self.animateObjectWillChange()
            }
        }
    }
}

public final class MessageRowViewModel: ObservableObject {
    public var isCalculated = false
    public var isEnglish = true
    public var markdownTitle = AttributedString()
    public var timeString: String = ""
    public static var avatarSize: CGFloat = 37
    public var reactionsVM: MessageReactionsViewModel
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
    public var canEdit: Bool { (message.editable == true && isMe) || (message.editable == true && threadVM?.thread.admin == true && threadVM?.thread.type?.isChannelType == true) }
    public var uploadViewModel: UploadFileViewModel?
    public var paddingEdgeInset: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    public var imageWidth: CGFloat = 128
    public var imageHeight: CGFloat = 128
    public var isReplyImage: Bool = false
    public var replyLink: String?
    private static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Language.preferredLocale
        return formatter
    }()

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
        reactionsVM = MessageReactionsViewModel()
        reactionsVM.viewModel = self
        if message.uploadFile != nil {
            uploadViewModel = .init(message: message)
            isMe = true
        }
        setupObservers()
        canShowIconFile = message.replyInfo?.messageType != .text && message.replyInfo?.message.isEmptyOrNil == true && message.replyInfo?.deleted == false
        let isReplyOrForward = (message.forwardInfo != nil || message.replyInfo != nil) && !message.isImage
        let tailWidth: CGFloat = 6
        let paddingLeading = isReplyOrForward ? (isMe ? 10 : 16) : (isMe ? 4 : 4 + tailWidth)
        let paddingTrailing: CGFloat = isReplyOrForward ? (isMe ? 16 : 10) : (isMe ? 4 + tailWidth : 4)
        let paddingTop: CGFloat = isReplyOrForward ? 10 : 4
        let paddingBottom: CGFloat = 4
        paddingEdgeInset = .init(top: paddingTop, leading: paddingLeading, bottom: paddingBottom, trailing: paddingTrailing)


        if message.isImage || message.isMapType {
            let isOnlyImage = (message.message ?? "").isEmpty == true && (message.replyInfo == nil) && (message.forwardInfo == nil)

            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let imageWidth = CGFloat(message.fileMetaData?.file?.actualWidth ?? 0)
            let minWidth: CGFloat = 128
            let maxWidth = ThreadViewModel.maxAllowedWidth - (18 + 6)
            let dynamicWidth = min(max(minWidth, imageWidth), maxWidth)
            self.imageWidth = isOnlyImage ? dynamicWidth : maxWidth

            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let imageHeight = CGFloat(message.fileMetaData?.file?.actualHeight ?? 0)
            let minHeight: CGFloat = 128
            let maxHeight: CGFloat = 320
            let dynamicHeight = min(max(minHeight, imageHeight), maxHeight)
            self.imageHeight = isOnlyImage ? dynamicHeight : maxHeight
        }

        /// Reply file info
        if let replyInfo = message.replyInfo {
            self.isReplyImage = [MessageType.picture, .podSpacePicture].contains(replyInfo.messageType)
            let metaData = replyInfo.metadata
            if let data = metaData?.data(using: .utf8), let fileMetaData = try? JSONDecoder.instance.decode(FileMetaData.self, from: data) {
                replyLink = fileMetaData.file?.link
            }
        }
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

        uploadViewModel?.$state.sink { [weak self] state in
            self?.deleteUploadedMessage(state: state)
        }
        .store(in: &cancelableSet)
    }

    @MainActor
    public func calculate() {
        if isCalculated { return }
        recalculateWithAnimation()
    }

    private func startHighlightTimer() {
        highlightTimer?.invalidate()
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
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
        Task {
            await performaCalculation()
            await MainActor.run {
                self.animateObjectWillChange()
            }
        }
    }

    private func performaCalculation() async {
        isCalculated = true
        isNextMessageTheSameUser = threadVM?.thread.group == true && (threadVM?.isNextSameUser(message: message) == true) && message.participant != nil
        isEnglish = message.message?.naturalTextAlignment == .leading
        markdownTitle = message.markdownTitle
        if let date = message.time?.date {
            timeString = MessageRowViewModel.formatter.string(from: date)
        }
    }

    private func deleteUploadedMessage(state: UploadFileState) {
        if state == .completed {
            threadVM?.uploadMessagesViewModel.cancel(message.uniqueId)
            threadVM?.unssetMessagesViewModel.cancel(message.uniqueId)
            threadVM?.historyVM.messageViewModels.removeAll(where: {$0.message.uniqueId == message.uniqueId})
            threadVM?.historyVM.onDeleteMessage(ChatResponse(uniqueId: message.uniqueId, subjectId: threadVM?.threadId))
            threadVM?.animateObjectWillChange()
            Logger.viewModels.info("Upload Message with uniqueId removed:\(self.message.uniqueId ?? "")")
        }
    }

    public static func isDeletable(isMe: Bool, message: Message, thread: Conversation?) -> (forMe: Bool, ForOthers: Bool) {
        let isChannel = thread?.type?.isChannelType == true
        let isGroup = thread?.group == true
        let isAdmin = thread?.admin == true
        if isMe {
            return (true, true)
        } else if !isMe && !isGroup {
            return (true, false)
        } else if isChannel && !isAdmin {
            return (false, false)
        } else if !isMe && isGroup && !isAdmin {
            return (true, false)
        } else if !isMe && isGroup && isAdmin {
            return (true, true)
        } else {
            return (false, false)
        }
    }

    deinit {
        downloadFileVM?.cancelObservers()
        downloadFileVM = nil
#if DEBUG
        Logger.viewModels.info("Deinit get called for message: \(self.message.message ?? "") and message isFileTye:\(self.message.isFileType) and id is: \(self.message.id ?? 0)")
#endif
    }
}
