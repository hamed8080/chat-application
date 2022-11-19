//
//  MessageViewModel.swift
//  ChatApplication
//
//  Created by hamed on 11/18/22.
//

import FanapPodChatSDK
import Foundation

protocol MessageViewModelProtocol {
    var message: Message { get set }
    var messageId: Int { get }
    var isMe: Bool { get }
    var type: MessageType? { get }
    var isTextMessageType: Bool { get }
    var isUploadMessage: Bool { get }
    var isFileType: Bool { get }
    func togglePin()
    func pin()
    func unpin()
    func clearCacheFile(message: Message)
}

class MessageViewModel: ObservableObject, MessageViewModelProtocol {
    @Published
    var message: Message

    var currentUser: User? { Chat.sharedInstance.userInfo ?? AppState.shared.user }

    var isMe: Bool { message.ownerId ?? 0 == currentUser?.id ?? 0 }

    var type: MessageType? { message.messageType ?? .unknown }

    var isTextMessageType: Bool { type == .text || isFileType }

    var isFileType: Bool { type == .podSpacePicture || type == .picture || type == .podSpaceFile || type == .file }

    var isUploadMessage: Bool { message is UploadFileMessage }

    var messageId: Int { message.id ?? 0 }

    init(message: Message) {
        self.message = message
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
            NotificationCenter.default.post(.init(name: File_Deleted_From_Cache_Name, object: message))
        }
    }
}
