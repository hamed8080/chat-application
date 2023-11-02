//
//  Notification.Name+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation
import Chat

public extension Notification.Name {
    static let chatEvents = Notification.Name("chatEvents")
    static let download = Notification.Name("download")
    static let upload = Notification.Name("upload")
    static let assistant = Notification.Name("assistant")
    static let file = Notification.Name("file")
    static let bot = Notification.Name("bot")
    static let participant = Notification.Name("participant")
    static let tag = Notification.Name("tag")
    static let map = Notification.Name("map")
    static let reaction = Notification.Name("reaction")
    static let user = Notification.Name("user")
    static let connect = Notification.Name("connect")
    static let message = Notification.Name("message")
    static let system = Notification.Name("system")
    static let thread = Notification.Name("thread")
    static let contact = Notification.Name("contact")
    static let call = Notification.Name("call")
    static let login = Notification.Name("login")
    static let logs = Notification.Name("logs")
    static let windowMode = Notification.Name("windowMode")
    static let closeSideBar = Notification.Name("closeSideBar")
    static let reactionMessageUpdated = Notification.Name("reactionMessageUpdated")
    static let galleryDownload = Notification.Name("galleryDownload")
    static let selectTab = Notification.Name("selectTab")
    static let senderSize = Notification.Name("senderSize")
}


public extension NotificationCenter {
    class func post(event: ChatEventType) {
        Self.default.post(name: .chatEvents, object: event)

        switch event {
        case let .bot(botEventTypes):
            Self.default.post(name: .bot, object: botEventTypes)
        case let .contact(contactEventTypes):
            Self.default.post(name: .contact, object: contactEventTypes)
        case let .download(downloadEventTypes):
            Self.default.post(name: .download, object: downloadEventTypes)
        case let .upload(uploadEventTypes):
            Self.default.post(name: .upload, object: uploadEventTypes)
        case let .system(systemEventTypes):
            Self.default.post(name: .system, object: systemEventTypes)
        case let .message(messageEventTypes):
            Self.default.post(name: .message, object: messageEventTypes)
        case let .thread(threadEventTypes):
            Self.default.post(name: .thread, object: threadEventTypes)
        case let .user(userEventTypes):
            Self.default.post(name: .user, object: userEventTypes)
        case let .assistant(assistantEventTypes):
            Self.default.post(name: .assistant, object: assistantEventTypes)
        case let .tag(tagEventTypes):
            Self.default.post(name: .tag, object: tagEventTypes)
        case let .call(callEventTypes):
            Self.default.post(name: .call, object: callEventTypes)
        case let .participant(participantEventTypes):
            Self.default.post(name: .participant, object: participantEventTypes)
        case let .map(mapEventTypes):
            Self.default.post(name: .map, object: mapEventTypes)
        case let .reaction(reactionEventTypes):
            Self.default.post(name: .reaction, object: reactionEventTypes)
        }
    }
}
