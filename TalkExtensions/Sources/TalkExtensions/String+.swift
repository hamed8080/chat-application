//
//  String+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 11/10/21.
//

import ChatModels
import UniformTypeIdentifiers
import SwiftUI
import NaturalLanguage

public extension String {

    func getSystemTypeString(type: SMT) -> String? {
        switch type {
        case .isTyping:
            return "typing"
        case .recordVoice:
            return "recording audio"
        case .uploadPicture:
            return "uploading image"
        case .uploadVideo:
            return "uploading video"
        case .uploadSound:
            return "uploading sound"
        case .uploadFile:
            return "uploading file"
        case .serverTime:
            return nil
        case .unknown:
            return "UNknown"
        }
    }

    func remove(in range: NSRange) -> String? {
        guard let range = Range(range, in: self) else { return nil }
        return replacingCharacters(in: range, with: "")
    }

    func matches(char: Character) -> [NSTextCheckingResult]? {
        let range = NSRange(startIndex..., in: self)
        return try? NSRegularExpression(pattern: "\(char)[0-9a-zA-Z\\-](\\.?[0-9a-zA-Z\\-])*").matches(in: self, range: range)
    }

    var systemImageNameForFileExtension: String {
        switch self {
        case ".mp4", ".avi", ".mkv":
            return "play.rectangle.fill"
        case ".mp3", ".m4a":
            return "play.circle.fill"
        case ".docx", ".pdf", ".xlsx", ".txt", ".ppt":
            return "doc.circle.fill"
        case ".zip", ".rar", ".7z":
            return "doc.zipper"
        default:
            return "doc.circle.fill"
        }
    }

    var nonCircleIconWithFileExtension: String {
        switch self {
        case "mp4", "avi", "mkv":
            return "film.fill"
        case "mp3", "m4a":
            return "music.note"
        case "docx", "pdf", "xlsx", "txt", "ppt":
            return "doc.text.fill"
        case "zip", "rar", "7z":
            return "doc.zipper"
        default:
            return "doc.fill"
        }
    }

    /// Convert mimeType to extension such as `audio/mpeg` to `mp3`.
    var ext: String? { UTType(mimeType: self)?.preferredFilenameExtension }

    var dominantLanguage: String? {
        return NLLanguageRecognizer.dominantLanguage(for: self)?.rawValue
    }

    var naturalTextAlignment: TextAlignment {
        guard let dominantLanguage = dominantLanguage else {
            return .leading
        }
        switch NSParagraphStyle.defaultWritingDirection(forLanguage: dominantLanguage) {
        case .leftToRight:
            return .leading
        case .rightToLeft:
            return .trailing
        case .natural:
            return .leading
        @unknown default:
            return .leading
        }
    }
}
