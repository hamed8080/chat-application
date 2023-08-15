//
//  ThreadTypes+.swift
//  ChatApplication
//
//  Created by hamed on 2/5/23.
//

import ChatModels

public extension ThreadTypes {
    var stringValue: String? {
        switch self {
        case .normal:
            return "Thread.normal"
        case .ownerGroup:
            return "Thread.ownerGroup"
        case .publicGroup:
            return "Thread.publicGroup"
        case .channelGroup:
            return "Thread.channelGroup"
        case .channel:
            return "Thread.channel"
        case .notificationChannel:
            return "Thread.notificationChannel"
        case .publicThread:
            return "Thread.publicThread"
        case .publicChannel:
            return "Thread.publicChannel"
        case .selfThread:
            return "Thread.selfThread"
        case .unknown:
            return nil
        }
    }
}
