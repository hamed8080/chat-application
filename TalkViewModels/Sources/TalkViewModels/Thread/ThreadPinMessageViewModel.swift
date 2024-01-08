//
//  ThreadPinMessageViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatModels
import UIKit
import ChatDTO
import Chat
import Combine
import SwiftUI
import ChatCore

public final class ThreadPinMessageViewModel: ObservableObject {
    public private(set) var text: String? = nil
    public private(set) var image: UIImage? = nil
    public private(set) var message: PinMessage?
    public private(set) var requestUniqueId: String?
    public private(set) var icon: String?
    public private(set) var isEnglish: Bool = true
    public private(set) var title: String = ""
    public private(set) var hasPinMessage: Bool = false
    private let thread: Conversation
    private var cancelable: Set<AnyCancellable> = []
    var threadId: Int {thread.id ?? -1}

    init(thread: Conversation) {
        self.thread = thread
        message = thread.pinMessage
        setupObservers()
        Task {
            downloadImageThumbnail()
            await calculate()
        }
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] event in
                self?.onDownloadEvent(event)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
    }

    private func onDownloadEvent(_ event: DownloadEventTypes) {
        switch event {
        case let .image(chatResponse, _):
            if requestUniqueId == chatResponse.uniqueId, let data = chatResponse.result {
                image = UIImage(data: data)
                animateObjectWillChange()
            }
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case let .pin(response):
            if threadId == response.subjectId {
                thread.pinMessage = response.result
                message = response.result
                downloadImageThumbnail()
                Task {
                    await calculate()
                }
            }
        case let .unpin(response):
            if threadId == response.subjectId {
                thread.pinMessage = nil
                message = nil
                Task {
                    await calculate()
                }
            }
        case .edited(let response):
            if response.result?.id == message?.id, let message = response.result {
                self.message = PinMessage(message: message)
                Task {
                    await calculate()
                }
            }
        default:
            break
        }
    }

    private func calculate() async {
        hasPinMessage = message != nil
        icon = fileMetadata?.file?.mimeType?.systemImageNameForFileExtension
        isEnglish = message?.text?.naturalTextAlignment == .leading
        title = messageText
        animateObjectWillChange()
    }

    private var messageText: String {
        if let text = message?.text, !text.isEmpty {
            return text.prefix(150).replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let fileName = fileMetadata?.name {
            return fileName
        } else {
            return ""
        }
    }

    var fileMetadata: FileMetaData? {
        guard let metdataData = message?.metadata?.data(using: .utf8),
              let file = try? JSONDecoder.instance.decode(FileMetaData.self, from: metdataData)
        else { return nil }
        return file
    }

    /// We use a Task due to fileMetadata decoding.
    private func downloadImageThumbnail() {
        Task {
            guard let file = fileMetadata,
                  let hashCode = file.file?.hashCode,
                  file.file?.mimeType == "image/jpeg" || file.file?.mimeType == "image/png"
            else {
                image = nil
                return
            }

            let req = ImageRequest(hashCode: hashCode, quality: 0.1, size: .SMALL, thumbnail: true)
            requestUniqueId = req.uniqueId
            ChatManager.activeInstance?.file.get(req)
        }
    }

    public func togglePinMessage(_ message: Message, notifyAll: Bool) {
        guard let messageId = message.id else { return }
        if message.pinned == false || message.pinned == nil {
            pinMessage(messageId, notifyAll: notifyAll)
        } else {
            unpinMessage(messageId)
        }
    }

    public func pinMessage(_ messageId: Int, notifyAll: Bool) {
        ChatManager.activeInstance?.message.pin(.init(messageId: messageId, notifyAll: notifyAll))
    }

    public func unpinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.unpin(.init(messageId: messageId))
    }
}
