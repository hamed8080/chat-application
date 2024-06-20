//
//  DownloadFileManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Combine
import Logger
import OSLog
import Chat
import TalkModels
import UIKit

public final class DownloadFileManager {
    private weak var viewModel: ThreadViewModel?
    private var downloadVMS: [DownloadFileViewModel] = []
    private var cancelableSet: Set<AnyCancellable> = Set()
    public static var emptyImage = UIImage(named: "empty_image")!
    public static var mapPlaceholder = UIImage(named: "map_placeholder")!
    private var queue = DispatchQueue(label: "DownloadFileManagerSerialQueue")
    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    internal func manageDownload(messageId: Int, isImage: Bool, isMap: Bool) async {
        guard let vm = viewModel(for: messageId) else { return }
        if isImage || isMap {
            await downloadImage(vm: vm, messageId: messageId)
        } else if isMap {
            downloadNormalFile(vm: vm)
        } else {
            downloadNormalFile(vm: vm)
        }
    }

    private func downloadImage(vm: DownloadFileViewModel, messageId: Int) async {
        if vm.thumbnailData == nil {
            vm.downloadBlurImage()
        } else {
            downloadNormalFile(vm: vm) // Download real image due to image thumbnail has been already on the screen
        }
    }

    private func downloadNormalFile(vm: DownloadFileViewModel) {
        if vm.state == .paused {
            vm.resumeDownload()
        } else if vm.state == .downloading {
            vm.pauseDownload()
        } else {
            vm.startDownload()
        }
    }

    public func viewModel(for messageId: Int) -> DownloadFileViewModel? {
        queue.sync {
            downloadVMS.first(where: {$0.message?.id == messageId})
        }
    }

    public func isContains(_ message: any HistoryMessageProtocol) -> Bool {
        queue.sync {
            return downloadVMS.contains(where: { $0.uniqueId == message.uniqueId })
        }
    }

    public func register(message: any HistoryMessageProtocol) {
        if isContains(message) { return }
        if message.isFileType && (message is UploadFileWithLocationMessage) == false, let message = message as? Message {
            let downloadFileVM = DownloadFileViewModel(message: message)
            let mtd = message.fileMetaData
            let isMap = mtd?.mapLink != nil || mtd?.latitude != nil
            let isVideo = message.isVideo
            let isImage = message.isImage
            queue.sync {
                downloadVMS.append(downloadFileVM)
            }
            downloadFileVM.objectWillChange.sink { [weak self] in
                Task { [weak self] in
                    if isVideo {
                        await self?.onVideoChanged(message: message)
                    } else if isImage || isMap {
                        await self?.onImageChanged(message: message, isMap: isMap)
                    } else {
                        await self?.onFileChanged(message: message)
                    }
                }
            }
            .store(in: &cancelableSet)
            Task {
                await downloadFileVM.setup()
            }
        }
    }

    private func unRegister(messageId: Int) {
        queue.sync {
            downloadVMS.removeAll(where: {$0.message?.id == messageId})
        }
    }

    private func realImage(vm: DownloadFileViewModel) -> UIImage? {
        guard let cgImage = vm.fileURL?.imageScale(width: 420)?.image else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func blurImage(vm: DownloadFileViewModel) -> UIImage? {
        guard let data = vm.thumbnailData, vm.state == .thumbnail else { return nil }
        return UIImage(data: data)
    }

    private func onVideoChanged(message: Message) async {
        guard let messageId = message.id, let vm = viewModel(for: messageId) else { return }
        let progress: CGFloat = CGFloat(await vm.downloadPercentValue())
        let state = MessageFileState(
            progress: min(CGFloat(progress) / 100, 1.0),
            showImage: true,
            showDownload: vm.state != .completed,
            state: vm.state,
            iconState: getIconState(vm: vm)
        )
        await changeStateTo(state: state, messageId: messageId)
    }

    private func onImageChanged(message: Message, isMap: Bool) async {
        guard let messageId = message.id else { return }
        guard let vm = viewModel(for: messageId) else { return }
        var showDownload = true
        var blurRadius: CGFloat = 16
        var preloadImage: UIImage? = nil
        let progress: CGFloat = CGFloat(await vm.downloadPercentValue())
        let iconState = getIconState(vm: vm)
        if vm.state == .completed {
            preloadImage = nil
            blurRadius = 0
            showDownload = false
            log("Image download has been completed with id: \(messageId) message:\(message.message ?? "")")
        } else if let blurImage = blurImage(vm: vm) {
            preloadImage = blurImage
            blurRadius = 16
            showDownload = true
            log("thumbnail created for id: \(messageId) message:\(message.message ?? "")")
        } else if vm.state == .downloading {
            blurRadius = 16
            showDownload = true
            log("Downloading the image with id: \(messageId) message:\(message.message ?? "")")
        } else {
            preloadImage = DownloadFileManager.emptyImage
            blurRadius = 0
            showDownload = true
            log("Image placeholder for image with id: \(messageId) message:\(message.message ?? "")")
        }

        if isMap, vm.state != .completed {
            preloadImage = DownloadFileManager.mapPlaceholder
            log("Map placeholder with message id: \(messageId) message:\(message.message ?? "")")
        }
        let state = MessageFileState(
            progress: min(CGFloat(progress) / 100, 1.0),
            showImage: true,
            showDownload: showDownload,
            state: vm.state,
            iconState: iconState,
            blurRadius: blurRadius,
            preloadImage: preloadImage
        )
        await changeStateTo(state: state, messageId: messageId)
    }

    private func onFileChanged(message: Message) async {
        guard let messageId = message.id, !message.isImage else { return }
        guard let vm = viewModel(for: messageId) else { return }
        let progress = await vm.downloadPercentValue()
        let state = MessageFileState(
            progress: min(CGFloat(progress) / 100, 1.0),
            showImage: true,
            showDownload: vm.state != .completed,
            state: vm.state,
            iconState: getIconState(vm: vm).replacingOccurrences(of: ".circle", with: "")
        )
        await changeStateTo(state: state, messageId: messageId)
    }

    private func getIconState(vm: DownloadFileViewModel) -> String {
        if let iconName = vm.message?.iconName, vm.state == .completed {
            return iconName
        } else if vm.state == .downloading {
            return "pause.fill"
        } else if vm.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    private func changeStateTo(state: MessageFileState, messageId: Int) async {
        guard let result = viewModel?.historyVM.sections.viewModelAndIndexPath(for: messageId) else {
            log("Index path could not be found for message id:\(messageId)")
            return
        }
        await MainActor.run {
            result.vm.setFileState(state)
            if state.state == .completed {
                viewModel?.delegate?.downloadCompleted(at: result.indexPath, viewModel: result.vm)
            } else if state.state == .thumbnail {
                viewModel?.delegate?.updateThumbnail(at: result.indexPath, viewModel: result.vm)
            } else {
                viewModel?.delegate?.updateProgress(at: result.indexPath, viewModel: result.vm)
            }
        }
        if state.state == .completed {
            unRegister(messageId: messageId)
        }
    }

    private func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}
