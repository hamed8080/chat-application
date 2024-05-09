//
//  MessageRowViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 3/9/23.
//

import Chat
import SwiftUI
import ChatModels
import TalkModels
import OSLog
import Combine

public final class MessageRowViewModel: ObservableObject, Identifiable, Hashable {
    public static func == (lhs: MessageRowViewModel, rhs: MessageRowViewModel) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public let uniqueId: String = UUID().uuidString
    public var id: Int { message.id ?? -1 }
    public var message: Message

    public var reactionsModel: ReactionRowsCalculated
    public var downloadFileVM: DownloadFileViewModel?
    public var uploadViewModel: UploadFileViewModel?
    public var avatarImageLoader: ImageLoaderViewModel?
    public weak var threadVM: ThreadViewModel?

    public var highlightTimer: Timer?
    public static var emptyImage = UIImage(named: "empty_image")!
    public var rowType = MessageViewRowType()
    public var calculatedMessage = MessageRowCalculatedData()
    public var sizes = MessageRowSizes()
    public var state = MessageRowState()
    private var cancelable: AnyCancellable?

    public var isDownloadCompleted: Bool {
        downloadFileVM?.state == .completed
    }

    public var isUploadCompleted: Bool {
        uploadViewModel == nil
    }

    public var isInDownloadOrUploadMode: Bool {
        return !isDownloadCompleted || !isUploadCompleted
    }

    public init(message: Message, viewModel: ThreadViewModel) {
        self.message = message
        self.threadVM = viewModel
        if message.isFileType {
            self.downloadFileVM = DownloadFileViewModel(message: message)
        }
        reactionsModel = .init(rows: [], topPadding: 0)
        if message.uploadFile != nil {
            uploadViewModel = .init(message: message)
        }
        registerObservers()
    }

    private func registerObservers() {
        cancelable = downloadFileVM?.objectWillChange.sink { [weak self] in
            Task { [weak self] in
                await self?.prepareImage()
                await self?.updateVideo()
            }
        }
    }

    private func startHighlightTimer() {
        highlightTimer?.invalidate()
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.state.isHighlited = false
            self?.animateObjectWillChange()
        }
    }

    public func recalculateWithAnimation() async {
        await performaCalculation()
        self.animateObjectWillChange()
    }

    public func performaCalculation() async {
        let result = await MessageRowCalculators.calculate(message: message, threadVM: threadVM)
        rowType = result.rowType
        calculatedMessage = result.data
        sizes = result.sizes
        setAvatarViewModel()
        await downloadFileVM?.setup()
        manageDownload()
        state.isInSelectMode = threadVM?.selectedMessagesViewModel.isInSelectMode ?? false
        setAvatarColor()
    }

    public func toggleSelection() {
        withAnimation(!state.isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
            state.isSelected.toggle()
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
        guard let vm = downloadFileVM, message.isImage && !rowType.isMap else { return }
        if vm.thumbnailData != nil && vm.state == .downloading { return }
        if vm.state == .completed, let realImage = realImage {
            calculatedMessage.image = realImage
            sizes.blurRadius = 0
            clearDownloadViewModel()
        } else if let blurImage = blurImage {
            state.isPreparingThumbnailImageForUploadedImage = false
            calculatedMessage.image = blurImage
            sizes.blurRadius = 16
        } else if state.isPreparingThumbnailImageForUploadedImage {
            // do nothing stay with the current uploaded image in local until it will set by a new thumbnail data.
            // It will help the UI stay stable during changes and not shaking after uploading image
        } else {
            calculatedMessage.image = MessageRowViewModel.emptyImage
            sizes.blurRadius = 0
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

    private func updateVideo() async {
        if message.isVideo, downloadFileVM?.state == .completed {
            await asyncAnimateObjectWillChange()
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
        if downloadFileVM == nil && calculatedMessage.image != MessageRowViewModel.emptyImage {
            AppState.shared.objectsContainer.appOverlayVM.galleryMessage = message
        } else if downloadFileVM?.state != .completed && downloadFileVM?.thumbnailData != nil {
            downloadFileVM?.startDownload()
        }
    }

    private func setAvatarViewModel() {
        if let image = message.participant?.image {
            avatarImageLoader = threadVM?.threadsViewModel?.avatars(for: image, metaData: nil, userName: calculatedMessage.avatarSplitedCharaters)
        }
    }

    public func setHighlight() {
        state.isHighlited = true
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
            state.isPreparingThumbnailImageForUploadedImage = true
            setAsDownloadedImage()
        }
    }

    private func setAsDownloadedImage() {
        guard let downloadVM = downloadFileVM, !downloadVM.isInCache, downloadVM.thumbnailData == nil || downloadVM.fileURL == nil else { return }
        downloadBlurImageWithDelay(downloadVM)
    }

    public func swapUploadMessageWith(_ message: Message) {
        uploadViewModel = nil
        self.message = message
        downloadFileVM?.message = message
        threadVM?.historyVM.appendToNeedUpdate(self)
    }

    private func setAvatarColor() {
        calculatedMessage.avatarColor = String.getMaterialColorByCharCode(str: message.participant?.name ?? message.participant?.username ?? "")
    }

    private func clearDownloadViewModel() {
        downloadFileVM?.cancelObservers()
        downloadFileVM = nil
        cancelable = nil
    }

    public func updateMessage(_ message: Message) {
        self.message = message
        if message.isFileType {
            self.downloadFileVM = DownloadFileViewModel(message: message)
        }
        if message.uploadFile != nil {
            uploadViewModel = .init(message: message)
        }
        calculatedMessage.canShowIconFile = message.replyInfo?.messageType != .text && message.replyInfo?.deleted == false
        sizes.width = nil
        sizes.height = nil
        registerObservers()
    }

    func setReaction(reactions: ReactionInMemoryCopy) async {
        reactionsModel = await MessageRowCalculators.calulateReactions(reactions: reactions)
    }

    deinit {
        clearDownloadViewModel()
#if DEBUG
        Logger.viewModels.info("Deinit get called for message: \(self.message.message ?? "") and message isFileTye:\(self.message.isFileType) and id is: \(self.message.id ?? 0)")
#endif
    }
}
