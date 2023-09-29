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
            return "doc.text"
        case .voice:
            return "play.circle"
        case .picture:
            return "photo.on.rectangle.angled"
        case .video:
            return "play.rectangle"
        case .sound:
            return "play.circle"
        case .file:
            return nil
        case .podSpacePicture:
            return "photo.on.rectangle.angled"
        case .podSpaceVideo:
            return "play.rectangle"
        case .podSpaceSound:
            return "play.circle"
        case .podSpaceVoice:
            return "play.circle"
        case .podSpaceFile:
            return nil
        case .link:
            return "link.circle"
        case .endCall:
            return "phone.arrow.down.left"
        case .startCall:
            return "phone.arrow.up.right"
        case .sticker:
            return "face.smiling"
        case .location:
            return "mmap.circle"
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
        case .file:
            return "file"
        case .podSpacePicture:
            return "picture"
        case .podSpaceVideo:
            return "video"
        case .podSpaceSound:
            return "sound"
        case .podSpaceVoice:
            return "voice"
        case .podSpaceFile:
            return "file"
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
