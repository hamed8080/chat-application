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
import TalkModels
import NaturalLanguage
import ChatDTO
import OSLog
import ChatCore
import Combine

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
    public var callText: String?
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
    public var groupMessageParticipantName: String?
    public var avatarImageLoader: ImageLoaderViewModel?
    public var replyContainerWidth: CGFloat?
    private var cancelable: AnyCancellable?

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
        canShowIconFile = message.replyInfo?.messageType != .text && message.replyInfo?.deleted == false
        registerObservers()
    }

    private func registerObservers() {
        cancelable = downloadFileVM?.objectWillChange.sink { [weak self] in
            Task { [weak self] in
                await self?.prepareImage()
            }
        }
    }

    private func startHighlightTimer() {
        highlightTimer?.invalidate()
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.isHighlited = false
            self?.animateObjectWillChange()
        }
    }

    private func calculatePaddings() {
        let isReplyOrForward = (message.forwardInfo != nil || message.replyInfo != nil) && !message.isImage
        let tailWidth: CGFloat = 6
        let paddingLeading = isReplyOrForward ? (isMe ? 10 : 16) : (isMe ? 4 : 4 + tailWidth)
        let paddingTrailing: CGFloat = isReplyOrForward ? (isMe ? 16 : 10) : (isMe ? 4 + tailWidth : 4)
        let paddingTop: CGFloat = isReplyOrForward ? 10 : 4
        let paddingBottom: CGFloat = 4
        paddingEdgeInset = .init(top: paddingTop, leading: paddingLeading, bottom: paddingBottom, trailing: paddingTrailing)
    }

    public func recalculateWithAnimation() async {
        await performaCalculation()
        self.animateObjectWillChange()
    }

    public func performaCalculation() async {
        isCalculated = true
        fileMetaData = message.fileMetaData /// decoding data so expensive if it will happen on the main thread.
        calculateImageSize()
        setReplyInfo()
        calculatePaddings()
        calculateCallTexts()
        await setAvatarViewModel()
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
        async let color = threadVM?.participantsColorVM.color(for: message.participant?.id ?? -1)
        participantColor = await Color(uiColor: color ?? .clear)
        await downloadFileVM?.setup()
        manageDownload()
        computedFileSize = calculateFileSize()
        extName = calculateFileTypeWithExt()
        fileName = calculateFileName()
        addOrRemoveParticipantsAttr = calculateAddOrRemoveParticipantRow()
        textViewPadding = calculateTextViewPadding()
        localizedReplyFileName = calculateLocalizeReplyFileName()
        calculateGroupParticipantName()
        replyContainerWidth = await calculateReplyContainerWidth()
    }

    private func calculateImageSize() {
        if message.isImage {
            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let imageWidth = CGFloat(fileMetaData?.file?.actualWidth ?? (message as? UploadFileWithTextMessage)?.uploadImageRequest?.wC ?? 0)
            let maxWidth = ThreadViewModel.maxAllowedWidth
            /// We use max to at least have a width, because there are times that maxWidth is nil.
            let imageHeight = CGFloat(fileMetaData?.file?.actualHeight ?? (message as? UploadFileWithTextMessage)?.uploadImageRequest?.hC ?? 0)
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

    private func setReplyInfo() {
        /// Reply file info
        if let replyInfo = message.replyInfo {
            self.isReplyImage = [MessageType.picture, .podSpacePicture].contains(replyInfo.messageType)
            let metaData = replyInfo.metadata
            if let data = metaData?.data(using: .utf8), let fileMetaData = try? JSONDecoder.instance.decode(FileMetaData.self, from: data) {
                replyLink = fileMetaData.file?.link
            }
        }
    }

    public static func isDeletable(isMe: Bool, message: Message, thread: Conversation?) -> (forMe: Bool, ForOthers: Bool) {
        let isChannel = thread?.type?.isChannelType == true
        let isGroup = thread?.group == true
        let isAdmin = thread?.admin == true
        let isSelfThread = thread?.type == .selfThread
        if isSelfThread {
            return (true, false)
        } else if isMe {
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

    @MainActor
    private func prepareImage() async {
        guard let vm = downloadFileVM else { return }
        if vm.thumbnailData != nil && vm.state == .downloading { return }
        if vm.state == .completed, let realImage = realImage {
            image = realImage
            blurRadius = 0
            clearDownloadViewModel()
        } else if let blurImage = blurImage {
            image = blurImage
            blurRadius = 16
        } else {
            image = MessageRowViewModel.emptyImage
            blurRadius = 0
        }
        await asyncAnimateObjectWillChange()
    }

    private func downloadBlurImageWithDelay(delay: TimeInterval = 1.0, _ downloadVM: DownloadFileViewModel) {
        /// We wait for 1.0 seconds to download the thumbnail image.
        /// If we upload the image for the first time we have to wait, due to a server process to make a thumbnail.
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
            downloadVM.downloadBlurImage()
        }
    }

    private func manageDownload() {
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
        if downloadFileVM == nil && image != MessageRowViewModel.emptyImage {
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
        let fileName = fileMetaData?.file?.name
        if fileName == "" || fileName == "blob", let originalName = fileMetaData?.file?.originalName {
            return originalName
        }
        return fileName ?? message.uploadFileName
    }

    private func calculateAddOrRemoveParticipantRow() -> AttributedString? {
        if ![.participantJoin, .participantLeft].contains(message.type) { return nil }
        let date = Date(milliseconds: Int64(message.time ?? 0)).localFormattedTime ?? ""
        return try? AttributedString(markdown: "\(message.addOrRemoveParticipantString ?? "") \(date)")
    }

    private func calculateTextViewPadding() -> EdgeInsets {
      return EdgeInsets(top: !message.isImage && message.replyInfo == nil && message.forwardInfo == nil ? 6 : 0, leading: 6, bottom: 0, trailing: 6)
    }

    private func calculateLocalizeReplyFileName() -> String? {
        if let message = message.replyInfo?.message?.prefix(150).replacingOccurrences(of: "\n", with: " "), !message.isEmpty {
            return message
        } else if let fileHint = message.replyFileStringName?.localized(), !fileHint.isEmpty {
            return fileHint
        } else {
            return nil
        }
    }

    private func calculateCallTexts() {
        if ![.endCall, .startCall].contains(message.type) { return }
        let date = Date(milliseconds: Int64(message.time ?? 0))
        callText = date.localFormattedTime
    }

    @MainActor
    private func setAvatarViewModel() {
        let userName = message.participant?.name ?? message.participant?.username
        if let image = message.participant?.image {
            avatarImageLoader = threadVM?.threadsViewModel?.avatars(for: image, metaData: nil, userName: userName)
        }
    }

    private func calculateGroupParticipantName() {
        let canShowGroupName = !isMe && threadVM?.thread.group == true && threadVM?.thread.type?.isChannelType == false
        && isFirstMessageOfTheUser
        if canShowGroupName {
            groupMessageParticipantName = message.participant?.contactName ?? message.participant?.name
        }
    }

    private func calculateReplyContainerWidth() async -> CGFloat? {
        guard let replyInfo = message.replyInfo else { return nil }
        let messageFileText = textForContianerCalculation()
        let textWidth = messageContainerTextWidth()

        let senderNameWithIconOrImageInReply = replySenderWidthWithIconOrImage(replyInfo: replyInfo)
        let maxWidthWithSender = max(textWidth, senderNameWithIconOrImageInReply)

        if !message.isImage, messageFileText.count < 60 {
            return max(senderNameWithIconOrImageInReply, maxWidthWithSender)
        } else if !message.isImage, replyInfo.message?.count ?? 0 < messageFileText.count {
            let maxAllowedWidth = min(maxWidthWithSender, ThreadViewModel.maxAllowedWidth)
            return maxAllowedWidth
        } else {
            return nil
        }
    }

    private func replyPrimaryMessageFileIconWidth() -> CGFloat {
        if fileName == nil || fileName?.isEmpty == true { return 0 }
        return 32
    }

    private func messageContainerTextWidth() -> CGFloat {
        let text = textForContianerCalculation()
        let font = UIFont(name: "IRANSansX", size: 14) ?? .systemFont(ofSize: 14)
        let textWidth = text.widthOfString(usingFont: font) + replyPrimaryMessageFileIconWidth()
        let minimumWidth: CGFloat = 128
        let maxOriginal = max(minimumWidth, textWidth + paddingEdgeInset.leading + paddingEdgeInset.trailing)
        return maxOriginal
    }

    private func textForContianerCalculation() -> String {
        let fileNameText = fileName ?? ""
        let messageText = message.message?.prefix(150).replacingOccurrences(of: "\n", with: " ") ?? ""
        let messageFileText = messageText.count > fileNameText.count ? messageText : fileNameText
        return messageFileText
    }

    private func replyIconOrImageWidth() -> CGFloat {
        let isReplyImageOrIcon = isReplyImage || canShowIconFile
        return isReplyImageOrIcon ? 32 : 0
    }

    private func replySenderWidthCalculation(replyInfo: ReplyInfo) -> CGFloat {
        let senderNameText = replyInfo.participant?.contactName ?? replyInfo.participant?.name ?? ""
        let senderFont = UIFont(name: "IRANSansX-Bold", size: 12) ?? .systemFont(ofSize: 12)
        let senderNameWidth = senderNameText.widthOfString(usingFont: senderFont)
        return senderNameWidth
    }

    private func replySenderWidthWithIconOrImage(replyInfo: ReplyInfo) -> CGFloat {
        let iconWidth = replyIconOrImageWidth()
        let senderNameWidth = replySenderWidthCalculation(replyInfo: replyInfo)
        let space: CGFloat = 1.5 + 32 /// 1.5 bar + 8 for padding + 8 for space between image and leading bar + 8 between image and sender name + 16 for padding
        let senderNameWithImageSize = senderNameWidth + space + iconWidth
        return senderNameWithImageSize
    }

    public func setHighlight() {
        isHighlited = true
        animateObjectWillChange()
        startHighlightTimer()
    }

    public func unpinMessage() {
        Task {
            message.pinned = false
            message.pinTime = nil
            await recalculateWithAnimation()
        }
    }

    public func pinMessage(time: UInt? ) {
        Task {
            message.pinned = true
            message.pinTime = time
            await recalculateWithAnimation()
        }
    }

    public func setDelivered() {
        message.delivered = true
        animateObjectWillChange()
    }

    public func setSent(messageTime: UInt?) {
        message.time = messageTime
        animateObjectWillChange()
    }

    public func setSeen() {
        message.delivered = true
        message.seen = true
        animateObjectWillChange()
    }

    public func setEdited(_ edited: Message) {
        Task {
            message.message = message.message
            message.time = message.time
            message.edited = true
            await recalculateWithAnimation()
        }
    }

    public func uploadCompleted(_ uniqueId: String?, _ fileMetaData: FileMetaData?, _ data: Data?, _ error: Error?) {
        if message.isImage {
            setAsDownloadedImage()
        }
    }

    private func setAsDownloadedImage() {
        guard let downloadVM = downloadFileVM, !downloadVM.isInCache, downloadVM.thumbnailData == nil || downloadVM.fileURL == nil else { return }
        downloadBlurImageWithDelay(downloadVM)
    }

    private func clearDownloadViewModel() {
        downloadFileVM?.cancelObservers()
        downloadFileVM = nil
        cancelable = nil
    }

    deinit {
        clearDownloadViewModel()
#if DEBUG
        Logger.viewModels.info("Deinit get called for message: \(self.message.message ?? "") and message isFileTye:\(self.message.isFileType) and id is: \(self.message.id ?? 0)")
#endif
    }
}
