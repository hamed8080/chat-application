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
    public var isInvalid = false

    public var reactionsModel: ReactionRowsCalculated = .init(rows: [], topPadding: 0)
    public var avatarImageLoader: ImageLoaderViewModel?
    public weak var threadVM: ThreadViewModel?

    private var highlightTimer: Timer?
    public var calMessage = MessageRowCalculatedData()
    public private(set) var fileState: MessageFileState = .init()
    public var shareDownloadedFile: Bool = false

    public init(message: Message, viewModel: ThreadViewModel) {
        self.message = message
        self.threadVM = viewModel
    }

    public func recalculateWithAnimation() async {
        await performaCalculation()
        self.animateObjectWillChange()
    }

    public func performaCalculation() async {
        if !fileState.isUploadCompleted {
            threadVM?.uploadFileManager.register(message: message)
        }
        threadVM?.downloadFileManager.register(message: message)
        calMessage = await MessageRowCalculators.calculate(message: message, threadVM: threadVM, oldData: calMessage)
        setAvatarViewModel()
    }

    public func toggleSelection() {
        withAnimation(!calMessage.state.isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
            calMessage.state.isSelected.toggle()
            threadVM?.selectedMessagesViewModel.animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    private func setAvatarViewModel() {
        if let image = message.participant?.image, !calMessage.isMe {
            avatarImageLoader = threadVM?.threadsViewModel?.avatars(for: image, metaData: nil, userName: calMessage.avatarSplitedCharaters)
        }
    }

    public func setFileState(_ state: MessageFileState) {
        fileState.update(state)
    }

    func invalid() {
        isInvalid = true
    }

    deinit {
#if DEBUG
        Logger.viewModels.info("Deinit get called for message: \(self.message.message ?? "") and message isFileTye:\(self.message.isFileType) and id is: \(self.message.id ?? 0)")
#endif
    }
}

// MARK: Prepare download managers
public extension MessageRowViewModel {
    func prepareForTumbnailIfNeeded() {
        if fileState.state != .completed && fileState.state != .thumbnail {
            manageDownload() // Start downloading thumbnail for the first time
        }
    }

    func downloadMap() {
        if calMessage.rowType.isMap && fileState.state != .completed {
            manageDownload() // Start downloading thumbnail for the first time
        }
    }
}

// MARK: Upload
public extension MessageRowViewModel {
    func swapUploadMessageWith(_ message: Message) {
        self.message = message
        threadVM?.historyVM.appendToNeedUpdate(self)
    }
}

// MARK: Tap actions
public extension MessageRowViewModel {
    func onTap() {
        if fileState.state == .completed {
            doAction()
        } else {
            manageDownload()
        }
    }

    private func manageDownload() {
        if let messageId = message.id {
            Task {
                await threadVM?.downloadFileManager.manageDownload(messageId: messageId, isImage: calMessage.rowType.isImage, isMap: calMessage.rowType.isMap)
            }
        }
    }

    private func doAction() {
        if calMessage.rowType.isMap {
            openMap()
        } else if calMessage.rowType.isImage {
            openImageViewer()
        } else if calMessage.rowType.isAudio {
            toggleAudio()
        } else {
            shareFile()
        }
    }

    private func shareFile() {
        Task {
            _ = await message.makeTempURL()
            await MainActor.run {
                shareDownloadedFile.toggle()
                objectWillChange.send()
            }
        }
    }

    private func openMap() {
        if let url = message.neshanURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func openImageViewer() {
        AppState.shared.objectsContainer.appOverlayVM.galleryMessage = message
    }

    func cancelUpload() {
        if let messageId = message.id {
            Task {
                await threadVM?.uploadFileManager.cancel(messageId: messageId)
            }
        }
    }
}

// MARK: Audio file
public extension MessageRowViewModel {
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    private var progress: CGFloat {
        isSameAudioFile ? min(audioVM.currentTime / audioVM.duration, 1.0) : 0
    }

    private var isSameAudioFile: Bool {
        fileState.url != nil && audioVM.fileURL?.absoluteString == fileState.url?.absoluteString
    }

    var audioTimerString: String {
        isSameAudioFile ? "\(audioVM.currentTime.timerString(locale: Language.preferredLocale) ?? "") / \(audioVM.duration.timerString(locale: Language.preferredLocale) ?? "")" : " " // We use space to prevent the text collapse
    }

    private func toggleAudio() {
        if isSameAudioFile {
            togglePlaying()
        } else {
            audioVM.close()
            togglePlaying()
        }
    }

    private func togglePlaying() {
        if let fileURL = fileState.url {
            let mtd = calMessage.fileMetaData
            try? audioVM.setup(message: message,
                               fileURL: fileURL,
                               ext: mtd?.file?.mimeType?.ext,
                               title: mtd?.file?.originalName ?? mtd?.name ?? "",
                               subtitle: mtd?.file?.originalName ?? "")
            audioVM.toggle()
        }
    }
}

// MARK: Reaction
public extension MessageRowViewModel {
    func clearReactions() {
        isInvalid = false
        reactionsModel = .init()
    }

    func setReaction(reactions: ReactionInMemoryCopy) async {
        isInvalid = false
        reactionsModel = await MessageRowCalculators.calulateReactions(reactions: reactions)
    }
}

// MARK: Update Message status
public extension MessageRowViewModel {
    func setDelivered() {
        message.delivered = true
        animateObjectWillChange()
    }

    func setSent(messageTime: UInt?) {
        message.time = messageTime
        animateObjectWillChange()
    }

    func setSeen() {
        message.delivered = true
        message.seen = true
        animateObjectWillChange()
    }
}

// MARK: Pin/UnPin Message
public extension MessageRowViewModel {
    func unpinMessage() {
        Task {
            message.pinned = false
            message.pinTime = nil
            await recalculateWithAnimation()
        }
    }

    func pinMessage(time: UInt? ) {
        Task {
            message.pinned = true
            message.pinTime = time
            await recalculateWithAnimation()
        }
    }
}

// MARK: Highlight
public extension MessageRowViewModel {

    func setHighlight() {
        calMessage.state.isHighlited = true
        animateObjectWillChange()
        startHighlightTimer()
    }

    private func startHighlightTimer() {
        highlightTimer?.invalidate()
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.calMessage.state.isHighlited = false
            self?.animateObjectWillChange()
        }
    }
}

// MARK: Edit Message
public extension MessageRowViewModel {
    func setEdited(_ edited: Message) {
        Task {
            message.message = message.message
            message.time = message.time
            message.edited = true
            await recalculateWithAnimation()
        }
    }
}
