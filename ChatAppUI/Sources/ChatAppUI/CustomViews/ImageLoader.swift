//
//  ImageLoader.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Foundation
import UIKit
import ChatAppViewModels
import ChatModels
import ChatAppModels
import ChatDTO
import ChatCore
import ChatAppExtensions
import Combine
import ChatTransceiver

private var token: String? {
    guard let data = UserDefaults.standard.data(forKey: TokenManager.ssoTokenKey),
          let ssoToken = try? JSONDecoder().decode(SSOTokenResponseResult.self, from: data)
    else {
        return nil
    }
    return ssoToken.accessToken
}

public final class ImageLoader: ObservableObject {
    @Published private(set) var image: UIImage = .init()
    private(set) var url: String?
    private(set) var fileMetadata: String?
    private(set) var size: ImageSize?
    private(set) var userName: String?
    private var requests: [String: Any] = [:]
    public private(set) var cancelable: Set<AnyCancellable> = []
    
    public init() {
        NotificationCenter.default.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink{ [weak self] event in
                self?.onDownloadEvent(event)
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

    var isImageReady: Bool {
        image.size.width > 0
    }

    private func setImage(data: Data) {
        autoreleasepool {
            if size == nil {
                image = UIImage(data: data) ?? UIImage()
            } else {
                guard let cgImage = data.imageScale(width: size == .SMALL ? 128 : 256)?.image else { return }
                image = UIImage(cgImage: cgImage)
            }
        }
    }

    private var URLObject: URL? { URL(string: url ?? "") }
    private var isSDKImage: Bool { hashCode != "" }
    private var fileMetadataModel: FileMetaData? {
        guard let fileMetadata = fileMetadata?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(FileMetaData.self, from: fileMetadata)
    }
    private var fileURL: URL? {
        guard let URLObject = URLObject else { return nil }
        let chat = ChatManager.activeInstance
        if chat?.file.isFileExist(URLObject) == true {
            return chat?.file.filePath(URLObject)
        } else if chat?.file.isFileExistInGroup(URLObject) == true {
            return chat?.file.filePathInGroup(URLObject)
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

    func fetch(url: String? = nil, metaData: String? = nil, userName: String? = nil, size: ImageSize = .SMALL) {
        fileMetadata = metaData
        self.url = url
        self.userName = userName
        self.size = size
        if url == nil {
            objectWillChange.send()
            return
        }
        if isSDKImage {
            getFromSDK()
        } else if let fileURL = fileURL {
            guard let cgImage = fileURL.imageScale(width: 128)?.image else { return }
            autoreleasepool {
                image = UIImage(cgImage: cgImage)
            }
        } else {
            downloadFromAnyURL()
        }
    }

    private func getFromSDK() {
        let req = ImageRequest(hashCode: hashCode, size: size ?? .LARG)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.file.get(req)
    }

    private func onGetImage(_ response: ChatResponse<Data>, _ url: URL?) {
        guard let uniqueId = response.uniqueId, requests[uniqueId] != nil else { return }
        if response.cache == false, let data = response.result {
            update(data: data)
            storeInCache(data: data) // For retrieving Widgetkit images with the help of the app group.
            requests.removeValue(forKey: uniqueId)
        } else {
            guard let cgImage = url?.imageScale(width: 128)?.image else { return }
            autoreleasepool {
                image = UIImage(cgImage: cgImage)
            }
        }
    }

    private func downloadFromAnyURL() {
        guard let req = reqWithHeader else { return }
        let task = URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            self?.update(data: data)
            self?.storeInCache(data: data)
        }
        task.resume()
    }

    private func update(data: Data?) {
        guard let data = data else { return }
        if !isRealImage(data: data) { return }
        DispatchQueue.main.async { [weak self] in
            self?.setImage(data: data)
        }
    }

    private func storeInCache(data: Data?) {
        guard let data = data else { return }
        if !isRealImage(data: data) { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let url = URL(string: self.url ?? "") else { return }
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
        var request = URLRequest(url: URLObject)
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }
}
