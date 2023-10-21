//
//  MessageType+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import ChatModels

public extension ChatModels.MessageType {
    var iconName: String? {
        switch self {
        case .text:
            return "doc.circle.fill"
        case .voice, .sound, .video, .podSpaceVoice, .podSpaceSound, .podSpaceVideo:
            return "play.circle.fill"
        case .picture, .podSpacePicture:
            return "photo.circle.fill"
        case .file, .podSpaceFile:
            return nil
        case .link:
            return "link.circle.fill"
        case .endCall:
            return "phone.arrow.down.left"
        case .startCall:
            return "phone.arrow.up.right"
        case .sticker:
            return "face.smiling"
        case .location:
            return "map.circle.fill"
        case .participantJoin:
            return "person.crop.rectangle.badge.plus"
        case .participantLeft:
            return "door.right.hand.open"
        case .unknown:
            return nil
        }
    }

    var fileStringName: String? {
        switch self {
        case .text:
            return "text"
        case .voice:
            return "voice"
        case .picture:
            return "picture"
        case .video:
            return "video"
        case .sound:
            return "sound"
        case .file, .podSpaceFile:
            return "doc.circle.fill"
        case .podSpacePicture:
            return "picture"
        case .podSpaceVideo:
            return "video"
        case .podSpaceSound:
            return "sound"
        case .podSpaceVoice:
            return "voice"
        case .link:
            return "link"
        case .endCall:
            return "end_call"
        case .startCall:
            return "start_call"
        case .sticker:
            return "sticker"
        case .location:
            return "location"
        case .participantJoin:
            return "join"
        case .participantLeft:
            return "left"
        case .unknown:
            return nil
        }
    }
}
