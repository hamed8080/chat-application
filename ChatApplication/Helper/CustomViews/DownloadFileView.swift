//
//  DownloadFileView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

struct DownloadFileView: View {
    @ObservedObject
    var downloadFileVM: DownloadFileViewModel

    @State
    var data: Data = .init()

    @State
    var percent: Int64 = 0

    @State
    var shareDownloadedFile: Bool = false

    init(message: Message, placeHolder: Data? = nil) {
        self.downloadFileVM = .init(message: message)
        if let placeHolder = placeHolder {
            downloadFileVM.data = placeHolder
        }
    }

    var body: some View {
        HStack {
            ZStack(alignment: .center) {
                switch downloadFileVM.state {
                case .COMPLETED:
                    if downloadFileVM.message.isImage, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: downloadFileVM.message.iconName)
                            .resizable()
                            .padding()
                            .foregroundColor(Color(named: "icon_color").opacity(0.8))
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .onTapGesture {
                                shareDownloadedFile.toggle()
                            }
                    }
                case .DOWNLOADING, .STARTED:
                    CircularProgressView(percent: $percent)
                        .padding()
                        .frame(maxWidth: 128)
                        .onTapGesture {
                            downloadFileVM.pauseDownload()
                        }
                case .PAUSED:
                    Image(systemName: "pause.circle")
                        .resizable()
                        .padding()
                        .font(.headline.weight(.thin))
                        .foregroundColor(.indigo)
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .frame(maxWidth: 128)
                        .onTapGesture {
                            downloadFileVM.resumeDownload()
                        }
                case .UNDEFINED:
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .blur(radius: 24)

                    Image(systemName: "arrow.down.circle")
                        .resizable()
                        .font(.headline.weight(.thin))
                        .padding(32)
                        .frame(width: 96, height: 96)
                        .scaledToFit()
                        .foregroundColor(.indigo)
                        .onTapGesture {
                            downloadFileVM.startDownload()
                        }
                default:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut, value: downloadFileVM.state)
        .animation(.easeInOut, value: data)
        .animation(.easeInOut, value: percent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(downloadFileVM.$data) { data in
            self.data = data ?? Data()
        }
        .onReceive(downloadFileVM.$downloadPercent) { percent in
            self.percent = percent
        }
        .sheet(isPresented: $shareDownloadedFile) {
            if let fileURL = downloadFileVM.fileURL {
                ActivityViewControllerWrapper(activityItems: [fileURL])
            } else {
                EmptyView()
            }
        }
    }
}

enum DownloadFileState {
    case STARTED
    case COMPLETED
    case DOWNLOADING
    case PAUSED
    case ERROR
    case UNDEFINED
}

protocol DownloadFileViewModelProtocol {
    var message: Message { get }
    var fileHashCode: String { get }
    var data: Data? { get }
    var state: DownloadFileState { get }
    var downloadUniqueId: String? { get }
    var downloadPercent: Int64 { get }
    var fileURL: URL? { get }
    func getFromCache()
    func startDownload()
    func pauseDownload()
    func resumeDownload()
}

class DownloadFileViewModel: ObservableObject, DownloadFileViewModelProtocol {
    @Published var downloadPercent: Int64 = 0
    @Published var state: DownloadFileState = .UNDEFINED
    @Published var data: Data? = nil
    var fileHashCode: String { message.metaData?.fileHash ?? "" }
    var fileURL: URL? { CacheFileManager.sharedInstance.getFileUrl(fileHashCode) }
    var downloadUniqueId: String?
    private(set) var message: Message
    private var cancelable: Set<AnyCancellable> = []

    init(message: Message) {
        self.message = message
        getFromCache()
        NotificationCenter.default.publisher(for: File_Deleted_From_Cache_Name)
            .compactMap { $0.object as? Message }
            .filter { $0.id == message.id }
            .sink { [weak self] receivedValue in
                self?.state = .UNDEFINED
            }
            .store(in: &cancelable)
    }

    func getFromCache() {
        if message.isImage {
            getImageIfExistInCache()
        } else {
            getFileIfExistInCache()
        }
    }

    func startDownload() {
        // It retrieved from cache
        if state == .COMPLETED { return }
        state = .DOWNLOADING
        if message.isImage {
            downloadImage()
        } else {
            downloadFile()
        }
    }

    private func downloadFile() {
        let req = FileRequest(hashCode: fileHashCode, forceToDownloadFromServer: true)
        Chat.sharedInstance.getFile(req: req) { downloadProgress in
            self.downloadPercent = downloadProgress.percent
        } completion: { [weak self] data, _, _ in
            self?.onResponse(data: data)
        } cacheResponse: { [weak self] data, _, _ in
            self?.onResponse(data: data)
        } uniqueIdResult: { uniqueId in
            self.downloadUniqueId = uniqueId
        }
    }

    private func downloadImage() {
        let req = ImageRequest(hashCode: fileHashCode, forceToDownloadFromServer: true, isThumbnail: false, size: .ACTUAL)
        Chat.sharedInstance.getImage(req: req) { [weak self] downloadProgress in
            self?.downloadPercent = downloadProgress.percent
        } completion: { [weak self] data, _, _ in
            self?.onResponse(data: data)
        } cacheResponse: { [weak self] data, _, _ in
            self?.onResponse(data: data)
        } uniqueIdResult: { [weak self] uniqueId in
            self?.downloadUniqueId = uniqueId
        }
    }

    private func getImageIfExistInCache(isThumbnail: Bool = true) {
        if CacheFileManager.sharedInstance.getImage(hashCode: fileHashCode) != nil {
            let req = ImageRequest(hashCode: fileHashCode, forceToDownloadFromServer: false, isThumbnail: false, size: .ACTUAL)
            Chat.sharedInstance.getImage(req: req) { _ in
            } completion: { _, _, _ in
            } cacheResponse: { [weak self] data, _, _ in
                self?.onResponse(data: data)
            }
        }
    }

    private func onResponse(data: Data?) {
        if let data = data {
            state = .COMPLETED
            downloadPercent = 100
            self.data = data
        }
    }

    private func getFileIfExistInCache() {
        if CacheFileManager.sharedInstance.getFile(hashCode: fileHashCode) != nil {
            let req = FileRequest(hashCode: fileHashCode, forceToDownloadFromServer: false)
            Chat.sharedInstance.getFile(req: req) { _ in
            } completion: { _, _, _ in
            } cacheResponse: { [weak self] data, _, _ in
                self?.onResponse(data: data)
            }
        }
    }

    func pauseDownload() {
        guard let downloadUniqueId = downloadUniqueId else { return }
        Chat.sharedInstance.manageDownload(uniqueId: downloadUniqueId, action: .suspend, isImage: true) { [weak self] _, _ in
            self?.state = .PAUSED
        }
    }

    func resumeDownload() {
        guard let downloadUniqueId = downloadUniqueId else { return }
        Chat.sharedInstance.manageDownload(uniqueId: downloadUniqueId, action: .resume, isImage: true) { [weak self] _, _ in
            self?.state = .DOWNLOADING
        }
    }
}

struct DownloadFileView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadFileView(message: Message(message: "Hello"), placeHolder: UIImage(named: "avatar")?.pngData())
    }
}
