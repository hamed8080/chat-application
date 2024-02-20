//
//  ImageLoaderViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Foundation
import UIKit
import ChatModels
import TalkModels
import ChatDTO
import ChatCore
import TalkExtensions
import Combine
import ChatTransceiver

private var token: String? {
    guard let data = UserDefaults.standard.data(forKey: TokenManager.ssoTokenKey),
          let ssoToken = try? JSONDecoder().decode(SSOTokenResponse.self, from: data)
    else {
        return nil
    }
    return ssoToken.accessToken
}

public struct ImageLoaderConfig {
    public let url: String
    public let metaData: String?
    public let userName: String?
    public let size: ImageSize
    public let forceToDownloadFromServer: Bool
    public let thumbnail: Bool
    
    public init(url: String, size: ImageSize = .SMALL, metaData: String? = nil, userName: String? = nil, thumbnail: Bool = false, forceToDownloadFromServer: Bool = false) {
        self.url = url
        self.metaData = metaData
        self.userName = userName
        self.size = size
        self.forceToDownloadFromServer = forceToDownloadFromServer
        self.thumbnail = thumbnail
    }
}

public final class ImageLoaderViewModel: ObservableObject {
    @Published public private(set) var image: UIImage = .init()
    private(set) var fileMetadata: String?
    public private(set) var cancelable: Set<AnyCancellable> = []
    var uniqueId: String?
    public var config: ImageLoaderConfig
    private var URLObject: URL? { URL(string: config.url) }
    private var isSDKImage: Bool { hashCode != "" }
    private var fileMetadataModel: FileMetaData? {
        guard let fileMetadata = fileMetadata?.data(using: .utf8) else { return nil }
        return try? JSONDecoder.instance.decode(FileMetaData.self, from: fileMetadata)
    }
    
    private var fileURL: URL? {
        guard let URLObject = URLObject, let fileManager = ChatManager.activeInstance?.file else { return nil }
        if fileManager.isFileExist(URLObject) {
            return fileManager.filePath(URLObject)
        } else if fileManager.isFileExistInGroup(URLObject) {
            return fileManager.filePathInGroup(URLObject)
        }
        return nil
    }

    var fileServerURL: URL? {
        guard let fileServer = ChatManager.activeInstance?.config.fileServer else { return nil }
        return URL(string: fileServer)
    }

    private var oldURLHash: String? {
        guard let urlObject = URLObject, let comp = URLComponents(url: urlObject, resolvingAgainstBaseURL: true) else { return nil }
        return comp.queryItems?.first(where: { $0.name == "hash" })?.value
    }

    private var hashCode: String { fileMetadataModel?.fileHash ?? oldURLHash ?? "" }

    public init(config: ImageLoaderConfig) {
        self.config = config
        NotificationCenter.download.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink{ [weak self] event in
                DispatchQueue.global().async {
                    self?.onDownloadEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    private func onDownloadEvent(_ event: DownloadEventTypes) {
        switch event {
        case .image(let chatResponse, let url):
            onGetImage(chatResponse, url)
        default:
            break
        }
    }

    public var isImageReady: Bool {
        image.size.width > 0
    }

    private func setImage(data: Data) {
        autoreleasepool {
            var image: UIImage? = nil
            if config.size == .ACTUAL {
                image = UIImage(data: data) ?? UIImage()
            } else {
                guard let cgImage = data.imageScale(width: config.size == .SMALL ? 128 : 256)?.image else { return }
                image = UIImage(cgImage: cgImage)
            }

            DispatchQueue.main.async { [weak self] in
                guard let image = image else { return }
                self?.image = image
            }
        }
    }

    private func setImage(fileURL: URL) {
        autoreleasepool {
            var image: UIImage? = nil
            if config.size == .ACTUAL, let data = fileURL.data {
                image = UIImage(data: data) ?? UIImage()
            } else {
                guard let cgImage = fileURL.imageScale(width: config.size == .SMALL ? 128 : 256)?.image else { return }
                image = UIImage(cgImage: cgImage)
            }
            DispatchQueue.main.async { [weak self] in
                guard let image = image else { return }
                self?.image = image
            }
        }
    }

    /// The hashCode decode FileMetaData so it needs to be done on the background thread.
    public func fetch() async {        
        fileMetadata = config.metaData
        if isSDKImage {
            await getFromSDK(forceToDownloadFromServer: config.forceToDownloadFromServer, thumbnail: config.thumbnail)
        } else if let fileURL = fileURL {
            setImage(fileURL: fileURL)
        } else {
            await downloadFromAnyURL(thumbnail: config.thumbnail)
        }
    }

    private func getFromSDK(forceToDownloadFromServer: Bool = false, thumbnail: Bool) async {
        let req = ImageRequest(hashCode: hashCode, forceToDownloadFromServer: config.forceToDownloadFromServer, size: config.size, thumbnail: config.thumbnail)
        uniqueId = req.uniqueId
        RequestsManager.shared.append(prepend: "ImageLoader", value: req)
        ChatManager.activeInstance?.file.get(req)
    }

    private func onGetImage(_ response: ChatResponse<Data>, _ url: URL?) {
        guard response.uniqueId == uniqueId else { return }
        if response.uniqueId == uniqueId, !response.cache, let data = response.result {
            response.pop(prepend: "ImageLoader")
            update(data: data)
            storeInCache(data: data) // For retrieving Widgetkit images with the help of the app group.
        } else {
            guard let url = url else { return }
            response.pop(prepend: "ImageLoader")
            setImage(fileURL: url)
        }
    }

    private func downloadFromAnyURL(thumbnail: Bool) async {
        guard let req = reqWithHeader else { return }
        let task = URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            self?.update(data: data)
            if !thumbnail {
                self?.uniqueId = nil
                self?.storeInCache(data: data)
            }
        }
        task.resume()
    }

    private func update(data: Data?) {
        guard let data = data else { return }
        if !isRealImage(data: data) { return }
        setImage(data: data)
    }

    private func storeInCache(data: Data?) {
        guard let data = data else { return }
        if !isRealImage(data: data) { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let url = URL(string: self.config.url) else { return }
            ChatManager.activeInstance?.file.saveFileInGroup(url: url, data: data) { _ in }
        }
    }

    /// Check if the response is not a string.
    private func isRealImage(data: Data) -> Bool {
        UIImage(data: data) != nil
    }

    private var headers: [String: String] { token != nil ? ["Authorization": "Bearer \(token ?? "")"] : [:] }

    private var reqWithHeader: URLRequest? {
        guard let URLObject else { return nil }
        let req = URLRequest(url: URLObject)
        uniqueId = "\(req.hashValue)"
        var request = URLRequest(url: URLObject)
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }
}
