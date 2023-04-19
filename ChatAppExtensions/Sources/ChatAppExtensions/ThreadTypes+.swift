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
            return "Normal(P2P/Group)"
        case .ownerGroup:
            return "Owner group"
        case .publicGroup:
            return "Public Group"
        case .channelGroup:
            return "Channel Group"
        case .channel:
            return "Channel"
        case .notificationChannel:
            return "Notification Channel"
        case .publicThread:
            return "Public thread"
        case .publicChannel:
            return "Public Channel"
        case .selfThread:
            return "Self thread"
        case .unknown:
            return nil
        }
    }
}
