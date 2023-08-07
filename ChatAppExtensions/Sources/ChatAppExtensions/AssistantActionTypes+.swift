//
//  AssistantActionTypes+.swift
//  ChatApplication
//
//  Created by hamed on 11/26/22.
//

import Foundation
import ChatModels
import SwiftUI

public extension AssistantActionTypes {
    var imageIconName: String? {
        switch self {
        case .register:
            return "rectangle.and.pencil.and.ellipsis"
        case .activate:
            return "play"
        case .deactivate:
            return "trash"
        case .block:
            return "hand.raised.slash"
        case .unblock:
            return "lock.open"
        case .unknown:
            return nil
        }
    }

    var actionColor: Color? {
        switch self {
        case .register:
            return .green
        case .activate:
            return .blue
        case .deactivate:
            return .yellow
        case .block:
            return .red
        case .unblock:
            return .mint
        case .unknown:
            return nil
        }
    }

    var stringValue: String? {
        switch self {
        case .register:
            return "activated"
        case .activate:
            return "activated"
        case .deactivate:
            return "deactivated"
        case .block:
            return "blocked"
        case .unblock:
            return "unblocked"
        case .unknown:
            return nil
        }
    }
}
