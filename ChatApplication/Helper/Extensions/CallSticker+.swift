//
//  CallSticker+.swift
//  ChatApplication
//
//  Created by hamed on 12/10/22.
//

import FanapPodChatSDK
import Foundation
import SwiftUI

extension CallSticker {
    var systemImage: Image {
        switch self {
        case .raiseHand:
            return Image(systemName: "hand.raised.fill")
        case .like:
            return Image(systemName: "hand.thumbsup.fill")
        case .dislike:
            return Image(systemName: "hand.thumbsdown.fill")
        case .clap:
            return Image(systemName: "hands.clap.fill")
        case .heart:
            return Image(systemName: "heart.fill")
        case .happy:
            return Image(systemName: "face.smiling.inverse")
        case .angry:
            return Image("angry")
        case .cry:
            return Image("crying")
        case .power:
            return Image(systemName: "bolt.fill")
        case .bored:
            return Image("bored")
        }
    }
}
