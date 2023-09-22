//
//  UNUserNotificationCenter+.swift
//  TalkExtensions
//
//  Created by hamed on 3/14/23.
//

import Foundation
import NotificationCenter
import ChatModels

public extension UNUserNotificationCenter {
    class func localNewMessageNotif(_ message: Message) {
        let content = UNMutableNotificationContent()
        content.badge = NSNumber(value: message.conversation?.unreadCount ?? 0)
        content.title = message.participant?.name ?? ""
        content.body = message.messageTitle
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request)
    }
}
