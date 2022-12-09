//
//  MessageViewModel.swift
//  ChatApplication
//
//  Created by hamed on 11/18/22.
//

import Combine
import FanapPodChatSDK
import Foundation

protocol MessageViewModelProtocol {
    var message: Message { get set }
    var messageId: Int { get }
    func togglePin()
    func pin()
    func unpin()
    func clearCacheFile(message: Message)
}

class MessageViewModel: ObservableObject, MessageViewModelProtocol {
    @Published var message: Message
    var messageId: Int { message.id ?? 0 }
    @Published var imageLoader: ImageLoader
    var cancellableSet: Set<AnyCancellable> = []

    init(message: Message) {
        self.message = message

        imageLoader = ImageLoader(url: message.participant?.image ?? "", userName: message.participant?.name ?? message.participant?.username, size: .SMALL)
        imageLoader.$image.sink { _ in
            self.objectWillChange.send()
        }
        .store(in: &cancellableSet)
        imageLoader.fetch()
    }

    func togglePin() {
        if message.pinned == false {
            pin()
        } else {
            unpin()
        }
    }

    func pin() {
        Chat.sharedInstance.pinMessage(.init(messageId: messageId)) { [weak self] messageId, _, error in
            if error == nil, messageId != nil {
                self?.message.pinned = true
            }
        }
    }

    func unpin() {
        Chat.sharedInstance.unpinMessage(.init(messageId: messageId)) { [weak self] messageId, _, error in
            if error == nil, messageId != nil {
                self?.message.pinned = false
            }
        }
    }

    func clearCacheFile(message: Message) {
        if let metadata = message.metadata?.data(using: .utf8), let fileHashCode = try? JSONDecoder().decode(FileMetaData.self, from: metadata).fileHash {
            CacheFileManager.sharedInstance.delete(fileHashCode: fileHashCode)
            NotificationCenter.default.post(.init(name: fileDeletedFromCacheName, object: message))
        }
    }
}
