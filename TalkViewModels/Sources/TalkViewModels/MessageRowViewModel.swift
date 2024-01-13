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
            .sink { [weak self] notification in
                self?.onReactionEvent(notification)
            }
            .store(in: &cancelableSet)
    }

    private func onReactionEvent(_ notification: Notification) {
        if notification.object as? Int == self.message?.id {
            Task {
                try? await Task.sleep(for: .seconds(0.1))
                await self.setReactionList()
            }
        }
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

public final class MessageRowViewModel: ObservableObject, Identifiable, Hashable {
    public static func == (lhs: MessageRowViewModel, rhs: MessageRowViewModel) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var id: Int { message.id ?? -1 }
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
    public var showReactionsOverlay = false
    public var isNextMessageTheSameUser: Bool = false
    public var isFirstMessageOfTheUser: Bool = false
    public var canShowIconFile: Bool = false
    public var canEdit: Bool { (message.editable == true && isMe) || (message.editable == true && threadVM?.thread.admin == true && threadVM?.thread.type?.isChannelType == true) }
    public var uploadViewModel: UploadFileViewModel?
    public var paddingEdgeInset: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    public var imageWidth: CGFloat? = nil
    public var imageHeight: CGFloat? = nil
    public var isReplyImage: Bool = false
    public var replyLink: String?
    public var isPublicLink: Bool = false
    public var participantColor: Color? = nil
    public var computedFileSize: String? = nil
    public var extName: String? = nil
    public var fileName: String? = nil
    public var blurRadius: CGFloat? = 0
    public var addOrRemoveParticipantsAttr: AttributedString? = nil
    public var textViewPadding: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    public var localizedReplyFileName: String? = nil
    private static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Language.preferredLocale
        return formatter
    }()
    public var isMapType: Bool = false
    public var fileMetaData: FileMetaData?
    private static var emptyImage = UIImage(named: "empty_image")!
    public var image: UIImage = MessageRowViewModel.emptyImage
    public var canShowImageView: Bool = false

    public var avatarImageLoader: ImageLoaderViewModel? {
        let userName = message.participant?.name ?? message.participant?.username
        if let image = message.participant?.image,
           let imageLoaderVM = threadVM?.threadsViewModel?.avatars(for: image, metaData: nil, userName: userName) {
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
                self?.animateObjectWillChange()
            }
            .store(in: &cancelableSet)

        NotificationCenter.default.publisher(for: Notification.Name("HIGHLIGHT"))
            .compactMap {$0.object as? Int}
            .sink { [weak self] newValue in
                if let messageId = self?.message.id, messageId == newValue {
                    self?.isHighlited = true
                    self?.animateObjectWillChange()
                    self?.startHighlightTimer()
                }
            }
            .store(in: &cancelableSet)
        threadVM?.$isInEditMode.sink { [weak self] newValue in
            /// Use if newValue != isInSelectMode to assure the newValue has arrived and all message rows will not get refreshed.
            if newValue != self?.isInSelectMode {
                self?.isInSelectMode = newValue
                self?.animateObjectWillChange()
            }
        }
        .store(in: &cancelableSet)

        NotificationCenter.default.publisher(for: .upload)
            .sink { [weak self] notification in
                self?.onUploadEventUpload(notification)
            }
            .store(in: &cancelableSet)

        downloadFileVM?.objectWillChange.sink { [weak self] in
            Task { [weak self] in
                await self?.prepareImage()
            }
        }
        .store(in: &cancelableSet)

        uploadViewModel?.$state.sink { [weak self] state in
            self?.deleteUploadedMessage(state: state)
        }
        .store(in: &cancelableSet)
    }

    private func startHighlightTimer() {
        highlightTimer?.invalidate()
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.isHighlited = false
            self?.animateObjectWillChange()
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
            animateObjectWillChange()
        }

        if case let .sent(response) = event, message.id == response.result?.messageId {
            message.id = response.result?.messageId
            message.time = response.result?.messageTime
            animateObjectWillChange()
        }

        if case let .delivered(response) = event, message.id == response.result?.messageId {
            message.delivered = true
            animateObjectWillChange()
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

    private func calculatePaddings() async {
        let isReplyOrForward = (message.forwardInfo != nil || message.replyInfo != nil) && !message.isImage
        let tailWidth: CGFloat = 6
        let paddingLeading = isReplyOrForward ? (isMe ? 10 : 16) : (isMe ? 4 : 4 + tailWidth)
        let paddingTrailing: CGFloat = isReplyOrForward ? (isMe ? 16 : 10) : (isMe ? 4 + tailWidth : 4)
        let paddingTop: CGFloat = isReplyOrForward ? 10 : 4
        let paddingBottom: CGFloat = 4
        paddingEdgeInset = .init(top: paddingTop, leading: paddingLeading, bottom: paddingBottom, trailing: paddingTrailing)
    }

    private func recalculateWithAnimation() {
        Task {
            await performaCalculation()
            await MainActor.run {
                self.animateObjectWillChange()
            }
        }
    }

    public func performaCalculation() async {
        isCalculated = true
        fileMetaData = message.fileMetaData /// decoding data so expensive if it will happen on the main thread.
        await calculateImageSize()
        await setReplyInfo()
        await calculatePaddings()
        isMapType = fileMetaData?.mapLink != nil || fileMetaData?.latitude != nil
        let isSameResponse = await (threadVM?.isNextSameUser(message: message) == true)
        let isFirstMessageOfTheUser = await (threadVM?.isFirstMessageOfTheUser(message) == true)
        isNextMessageTheSameUser = threadVM?.thread.group == true && isSameResponse && message.participant != nil
        self.isFirstMessageOfTheUser = threadVM?.thread.group == true && isFirstMessageOfTheUser
        isEnglish = message.message?.naturalTextAlignment == .leading
        markdownTitle = AttributedString(message.markdownTitle)
        isPublicLink = message.isPublicLink
        if let date = message.time?.date {
            timeString = MessageRowViewModel.formatter.string(from: date)
        }
        let uploadCompleted: Bool = message.uploadFile == nil || uploadViewModel?.state == .completed
        canShowImageView = !isMapType && message.isImage && uploadCompleted
        let color = await threadVM?.participantsColorVM.color(for: message.participant?.id ?? -1)
        participantColor = Color(uiColor: color ?? .clear)
        await manageDownload()
        computedFileSize = calculateFileSize()
        extName = calculateFileTypeWithExt()
        fileName = calculateFileName()
        addOrRemoveParticipantsAttr = calculateAddOrRemoveParticipantRow()
        textViewPadding = calculateTextViewPadding()
        localizedReplyFileName = calculateLocalizeReplyFileName()
    }

    private func calculateImageSize() async {
        if message.isImage {
            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let imageWidth = CGFloat(fileMetaData?.file?.actualWidth ?? 0)
            let maxWidth = ThreadViewModel.maxAllowedWidth
            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let imageHeight = CGFloat(fileMetaData?.file?.actualHeight ?? 0)
            let originalWidth: CGFloat = imageWidth
            let originalHeight: CGFloat = imageHeight
            var designerWidth: CGFloat = maxWidth
            var designerHeight: CGFloat = maxWidth
            let originalRatio: CGFloat = originalWidth / originalHeight
            let designRatio: CGFloat = designerWidth / designerHeight
            if originalRatio > designRatio {
                designerHeight = designerWidth / originalRatio
            } else {
                designerWidth = designerHeight * originalRatio
            }
            let isSquare = originalRatio >= 1 && originalRatio <= 1.5
            self.imageWidth = isSquare ? designerWidth : designerWidth * 1.5
            self.imageHeight = isSquare ? designerHeight : designerHeight * 1.5
        }
    }

    private func setReplyInfo() async {
        /// Reply file info
        if let replyInfo = message.replyInfo {
            self.isReplyImage = [MessageType.picture, .podSpacePicture].contains(replyInfo.messageType)
            let metaData = replyInfo.metadata
            if let data = metaData?.data(using: .utf8), let fileMetaData = try? JSONDecoder.instance.decode(FileMetaData.self, from: data) {
                replyLink = fileMetaData.file?.link
            }
        }
    }

    private func deleteUploadedMessage(state: UploadFileState) {
        if state == .completed {
            threadVM?.uploadMessagesViewModel.cancel(message.uniqueId)
            threadVM?.unssetMessagesViewModel.cancel(message.uniqueId)
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

    public func toggleSelection() {
        withAnimation(!isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
            isSelected.toggle()
            threadVM?.selectedMessagesViewModel.animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    private var realImage: UIImage? {
        guard let cgImage = downloadFileVM?.fileURL?.imageScale(width: 420)?.image else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private var blurImage: UIImage? {
        guard let data = downloadFileVM?.thumbnailData, downloadFileVM?.state == .thumbnail || downloadFileVM?.state == .downloading else { return nil }
        return UIImage(data: data)
    }

    private func prepareImage() async {
        if downloadFileVM?.state == .completed, let realImage = realImage {
            image = realImage
            blurRadius = 0
        } else if let blurImage = blurImage {
            image = blurImage
            blurRadius = 16
        } else {
            image = MessageRowViewModel.emptyImage
            blurRadius = 0
        }
        animateObjectWillChange()
        //        if downloadFileVM?.state == .completed {
        //            self.downloadFileVM?.thumbnailData = nil
        //            self.downloadFileVM?.data = nil
        //        }
    }

    private func onUploadEventUpload(_ notification: Notification) {
        guard
            let event = notification.object as? UploadEventTypes,
            case .completed(uniqueId: _, fileMetaData: _, data: _, error: _) = event,
            let downloadVM = downloadFileVM,
            !downloadVM.isInCache,
            downloadVM.thumbnailData == nil || downloadVM.fileURL == nil
        else { return }
        downloadBlurImageWithDelay(downloadVM)
    }

    private func downloadBlurImageWithDelay(delay: TimeInterval = 1.0, _ downloadVM: DownloadFileViewModel) {
        /// We wait for 2 seconds to download the thumbnail image.
        /// If we upload the image for the first time we have to wait, due to a server process to make a thumbnail.
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
            downloadVM.downloadBlurImage()
        }
    }

    private func manageDownload() async {
        if !message.isImage { return }
        if downloadFileVM?.isInCache == false, downloadFileVM?.thumbnailData == nil {
            downloadFileVM?.downloadBlurImage()
        } else if downloadFileVM?.isInCache == true {
            downloadFileVM?.state = .completed // it will set the state to complete and then push objectWillChange to call onReceive and start scale the image on the background thread
            downloadFileVM?.animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    public func onTap() {
        if downloadFileVM?.state == .completed {
            AppState.shared.objectsContainer.appOverlayVM.galleryMessage = message
        } else if downloadFileVM?.state != .completed && downloadFileVM?.thumbnailData != nil {
            downloadFileVM?.startDownload()
        }
    }

    private func calculateFileSize() -> String? {
        let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
        let realServerFileSize = fileMetaData?.file?.size
        let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale)?.replacingOccurrences(of: "٫", with: ".")
        return fileSize
    }

    private func calculateFileTypeWithExt() -> String? {
        let split = fileMetaData?.file?.originalName?.split(separator: ".")
        let ext = fileMetaData?.file?.extension
        let lastSplit = String(split?.last ?? "")
        let extensionName = (ext ?? lastSplit)
        return extensionName.isEmpty ? nil : extensionName.uppercased()
    }

    private func calculateFileName() -> String? {
       return fileMetaData?.file?.name ?? message.uploadFileName
    }

    private func calculateAddOrRemoveParticipantRow() -> AttributedString? {
        let date = Date(milliseconds: Int64(message.time ?? 0)).localFormattedTime ?? ""
        return try? AttributedString(markdown: "\(message.addOrRemoveParticipantString ?? "") - \(date)")
    }

    private func calculateTextViewPadding() -> EdgeInsets {
      return EdgeInsets(top: !message.isImage && message.replyInfo == nil && message.forwardInfo == nil ? 6 : 0, leading: 6, bottom: 0, trailing: 6)
    }

    private func calculateLocalizeReplyFileName() -> String? {
        let hinTextMessage = message.replyInfo?.message ?? message.replyFileStringName?.localized()
        return hinTextMessage
    }

    deinit {
        downloadFileVM?.cancelObservers()
        downloadFileVM = nil
#if DEBUG
        Logger.viewModels.info("Deinit get called for message: \(self.message.message ?? "") and message isFileTye:\(self.message.isFileType) and id is: \(self.message.id ?? 0)")
#endif
    }
}
