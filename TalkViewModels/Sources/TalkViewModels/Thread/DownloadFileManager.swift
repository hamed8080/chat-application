//
//  DownloadFileManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Combine
import ChatModels
import Logger
import OSLog
import Chat
import TalkModels
import UIKit

public final class DownloadFileManager: ObservableObject {
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
        if isImage {
            await downloadImage(vm: vm, messageId: messageId)
        } else if isMap {
            downloadNormalFile(vm: vm)
        } else {
            downloadNormalFile(vm: vm)
        }
    }

    private func downloadImage(vm: DownloadFileViewModel, messageId: Int) async {
        if vm.isInCache {
            guard let data = vm.data, let image = UIImage(data: data) else { return }
            await changeStateTo(state: .init(showImage: true, state: .completed, blurRadius: 0, image: image), messageId: messageId)
        } else if vm.isInCache == false && vm.thumbnailData == nil {
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

    public func register(message: Message) {
        if message.isFileType && (message is UploadFileWithLocationMessage) == false {
            let copy = message.copy
            let downloadFileVM = DownloadFileViewModel(message: copy)
            queue.sync {
                downloadVMS.append(downloadFileVM)
            }
            downloadFileVM.objectWillChange.sink { [weak self] in
                Task { [weak self] in
                    let mtd = copy.fileMetaData
                    let isMap = mtd?.mapLink != nil || mtd?.latitude != nil
                    if copy.isVideo {
                        await self?.onVideoChanged(message: message)
                    } else if copy.isImage || isMap {
                        await self?.onImageChanged(message: copy, isMap: isMap)
                    } else {
                        await self?.onFileChanged(message: copy)
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
        let progress: CGFloat = CGFloat(vm.downloadPercent)
        let state = MessageFileState(
            url: vm.fileURL,
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
        var image: UIImage? = nil
        let progress: CGFloat = CGFloat(vm.downloadPercent)
        let iconState = getIconState(vm: vm)
        if vm.state == .completed, let realImage = realImage(vm: vm) {
            image = realImage
            blurRadius = 0
            showDownload = false
        } else if let blurImage = blurImage(vm: vm) {
            image = blurImage
            blurRadius = 16
            showDownload = true
        } else if vm.state == .downloading {
            blurRadius = 16
            showDownload = true
        } else {
            image = DownloadFileManager.emptyImage
            blurRadius = 0
            showDownload = true
        }

        if isMap, vm.state != .completed {
            image = DownloadFileManager.mapPlaceholder
        }
        let state = MessageFileState(
            progress: min(CGFloat(progress) / 100, 1.0),
            showImage: true,
            showDownload: showDownload,
            state: vm.state,
            iconState: iconState,
            blurRadius: blurRadius,
            image: image
        )
        await changeStateTo(state: state, messageId: messageId)
    }

    private func onFileChanged(message: Message) async {
        guard let messageId = message.id, !message.isImage else { return }
        guard let vm = viewModel(for: messageId) else { return }
        let progress = vm.downloadPercent
        let state = MessageFileState(
            url: message.fileURL,
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
        let vm = viewModel?.historyVM.messageViewModel(for: messageId)
        await MainActor.run {
            guard let vm = vm else { return }
            vm.setFileState(state)
            vm.animateObjectWillChange()
        }
        if state.state == .completed {
            unRegister(messageId: messageId)
        }
    }
}
