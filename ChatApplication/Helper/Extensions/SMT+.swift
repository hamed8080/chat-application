//
//  SMT+.swift
//  ChatApplication
//
//  Created by hamed on 2/4/23.
//

import FanapPodChatSDK
import Foundation

extension SMT {
    typealias EventResult = (title: String, image: String)?

    var titleAndIcon: EventResult {
        guard let stringEvent, let eventImage else { return nil }
        return (stringEvent, eventImage)
    }

    var stringEvent: String? {
        switch self {
        case .isTyping:
            return "is typing..."
        case .recordVoice:
            return "is recording a voice"
        case .uploadPicture:
            return "is uploading an image"
        case .uploadVideo:
            return "is uploading a video"
        case .uploadSound:
            return "is uploading a sound"
        case .uploadFile:
            return "is uploading a file"
        case .unknown, .serverTime:
            return nil
        }
    }

    var eventImage: String? {
        switch self {
        case .isTyping:
            return "highlighter"
        case .recordVoice:
            return "waveform"
        case .uploadPicture:
            return "text.below.photo"
        case .uploadVideo:
            return "video.and.waveform"
        case .uploadSound:
            return "music.note"
        case .uploadFile:
            return "doc"
        case .unknown, .serverTime:
            return nil
        }
    }
}
