//
//  UploadFileManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Combine
import Chat
import TalkModels
import UIKit
import TalkExtensions

public final class UploadFileManager {
    private weak var viewModel: ThreadViewModel?
    private var uploadVMS: [String: UploadFileViewModel] = [:]
    private var cancelableSet: Set<AnyCancellable> = Set()
    private var queue = DispatchQueue(label: "UploadFileManagerSerialQueue")
    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    private func viewModel(for viewModelUniqueId: String) -> UploadFileViewModel? {
        queue.sync {
            uploadVMS.first(where: {$0.key == viewModelUniqueId})?.value
        }
    }

    public func register(message: any HistoryMessageProtocol, viewModelUniqueId: String) {
        queue.sync {
            let isInQueue = uploadVMS.contains(where: {$0.key == viewModelUniqueId})
            let isFileOrMap = message is UploadProtocol
            let canUpload = isFileOrMap && !isInQueue
            if canUpload {
                let uploadFileVM = UploadFileViewModel(message: message)

                uploadVMS[viewModelUniqueId] = uploadFileVM
                uploadFileVM.objectWillChange.sink { [weak self] in
                    Task { [weak self] in
                        await self?.onUploadChanged(uploadFileVM, message, viewModelUniqueId: viewModelUniqueId)
                    }
                }
                .store(in: &cancelableSet)
                if message.isImage || message is UploadFileWithLocationMessage {
                    uploadFileVM.startUploadImage()
                } else {
                    uploadFileVM.startUploadFile()
                }
            }
        }
    }

    private func unRegister(viewModelUniqueId: String) {
        queue.sync {
            // $0.message.id == nil in uploading locaiton is nil
            if uploadVMS.contains(where: {$0.key == viewModelUniqueId}) {
                uploadVMS.removeValue(forKey: viewModelUniqueId)
            }
        }
    }

    public func cancel(viewModelUniqueId: String) async {
        if let vm = uploadVMS.first(where: {$0.key == viewModelUniqueId})?.value {
            vm.cancelUpload()
            unRegister(viewModelUniqueId: viewModelUniqueId)
        }
    }

    private func getIconState(vm: UploadFileViewModel) -> String {
        if vm.state == .uploading {
            return "xmark"
        } else if vm.state == .paused {
            return "play.fill"
        } else if vm.state == .completed {
            return vm.message.iconName?.replacingOccurrences(of: ".circle", with: "") ?? "arrow.down"
        } else {
            return "arrow.up"
        }
    }

    private func onUploadChanged(_ vm: UploadFileViewModel, _ message: any HistoryMessageProtocol, viewModelUniqueId: String) async {
        let isCompleted = vm.state == .completed
        let isUploading = vm.state == .uploading
        let progress = min(CGFloat(vm.uploadPercent) / 100, 1.0)
        let iconState = getIconState(vm: vm)
        var image: UIImage?
        var blurRadius: CGFloat = 0
        if let data = (message as? UploadFileMessage)?.uploadImageRequest?.dataToSend, let uiimage = UIImage(data: data) {
            image = uiimage
        }

        if message.isImage, !isCompleted {
            blurRadius = 16
        }
        let finalURL = getURL(vm: vm)
        let fileState = MessageFileState.init(url: finalURL,
                                              progress: progress,
                                              isUploading: isUploading,
                                              isUploadCompleted: isCompleted,
                                              state: isCompleted ? .completed : .undefined,
                                              iconState: iconState,
                                              blurRadius: blurRadius,
                                              image: image
        )
        await changeStateTo(state: fileState, viewModelUniqueId: viewModelUniqueId)
    }

    @HistoryActor
    private func changeStateTo(state: MessageFileState, viewModelUniqueId: String) async {
        let vm = viewModel?.historyVM.sections.messageViewModel(viewModelUniqueId: viewModelUniqueId)
        await MainActor.run {
            guard let vm = vm else { return }
            vm.setFileState(state)
        }
        if state.isUploadCompleted {
            unRegister(viewModelUniqueId: viewModelUniqueId)
        }
    }

    public func getURL(vm: UploadFileViewModel) -> URL? {
        if vm.state != .completed { return nil }
        if let urlString = vm.fileMetaData?.file?.link, let url = URL(string: urlString) {
            let fileURL = ChatManager.activeInstance?.file.filePath(url)
            return fileURL
        }
        return nil
    }
}
