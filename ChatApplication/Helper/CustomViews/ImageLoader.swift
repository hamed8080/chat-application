//
//  ImageLoader.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import Foundation
import UIKit

class ImageLoader: ObservableObject {
    @Published
    private(set) var image: UIImage = .init()
    private(set) var url: String
    private(set) var fileMetadata: String?
    private(set) var size: ImageSize?
    private(set) var token: String?

    init(url: String) {
        self.url = url
    }

    var isImageReady: Bool {
        image.size.width > 0
    }

    private func setImage(data: Data) {
        if size == nil {
            image = UIImage(data: data) ?? UIImage()
        } else {
            image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: size == .SMALL ? 128 : 256, height: size == .SMALL ? 128 : 256)) ?? UIImage()
        }
    }

    private var URLObject: URL? { URL(string: url) }

    private var isSDKImage: Bool { hashCode != "" }

    private var fileMetadataModel: FileMetaData? { try? JSONDecoder().decode(FileMetaData.self, from: fileMetadata?.data(using: .utf8) ?? Data()) }

    private var cacheData: Data? { CacheFileManager.sharedInstance.getImageProfileCache(url: url, group: AppGroup.group) }

    private var oldURLHash: String? {
        guard let URLObject = URLObject else { return nil }
        return URLComponents(url: URLObject, resolvingAgainstBaseURL: true)?.queryItems?.first(where: { $0.name == "hash" })?.value
    }

    private var hashCode: String { fileMetadataModel?.fileHash ?? oldURLHash ?? "" }

    func fetch() {
        if isSDKImage {
            getFromSDK()
        } else if let data = cacheData {
            update(data: data)
        } else {
            downloadFromAnyURL()
        }
    }

    private func getFromSDK() {
        Chat.sharedInstance.getImage(req: .init(hashCode: hashCode, size: size ?? .SMALL)) { _ in
        } completion: { [weak self] data, _, _ in
            self?.update(data: data)
        } cacheResponse: { [weak self] data, _, _ in
            self?.update(data: data)
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
        DispatchQueue.main.async {
            self.setImage(data: data)
        }
    }

    private func storeInCache(data: Data?) {
        guard let data = data else { return }
        if !isRealImage(data: data) { return }
        DispatchQueue.main.async {
            CacheFileManager.sharedInstance.saveImageProfile(url: self.url, data: data, group: AppGroup.group)
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
