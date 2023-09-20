//
//  Sticker+.swift
//  Talk
//
//  Created by hamed on 8/12/23.
//

import Foundation
import ChatModels

public extension Sticker {
    var string: String {
        switch self {
        case .hifive:
            return "hifive"
        case .like:
            return "like"
        case .happy:
            return "happy"
        case .cry:
            return "cry"
        case .unknown:
            return "unknown"
        }
    }

    var emoji: String {
        switch self {
        case .hifive:
            return "👋"
        case .like:
            return "❤️"
        case .happy:
            return "😂"
        case .cry:
            return "😭"
        case .unknown:
            return ""
        }
    }
}
