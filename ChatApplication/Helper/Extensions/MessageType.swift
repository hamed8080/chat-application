//
//  MessageType.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/1/21.
//

import FanapPodChatSDK

extension Message{
    
    var iconName:String{
        switch MessageType(rawValue: messageType ?? 0) {
        case .TEXT:
            return "doc.text.fill"
        case .VOICE:
            return "play.circle.fill"
        case .PICTURE:
            return "photo.on.rectangle.angled"
        case .VIDEO:
            return "play.rectangle.fill"
        case .SOUND:
            return "play.circle.fill"
        case .FILE:
            return fileExtIcon
        case .POD_SPACE_PICTURE:
            return "photo.on.rectangle.angled"
        case .POD_SPACE_VIDEO:
            return "play.rectangle.fill"
        case .POD_SPACE_SOUND:
            return "play.circle.fill"
        case .POD_SPACE_VOICE:
            return "play.circle.fill"
        case .POD_SPACE_FILE:
            return fileExtIcon
        case .LINK:
            return "link.circle.fill"
        case .END_CALL:
            return "phone.fill.arrow.down.left"
        case .START_CALL:
            return "phone.fill.arrow.up.right"
        case .STICKER:
            return "face.smiling.fill"
        case .LOCATION:
            return "map.fill"
        case .none:
            return "paperclip.circle.fill"
        }
    }
    
    var fileExtIcon:String{
        switch metaData?.file?.extension ?? ""{
        case ".mp4",".avi",".mkv":
            return "play.rectangle.fill"
        case ".mp3",".m4a":
            return "play.circle.fill"
        case ".docx",".pdf",".xlsx",".txt",".ppt":
            return "doc.fill"
        case ".zip",".rar",".7z":
            return "doc.zipper"
        default:
            return "paperclip.circle.fill"
        }
    }
    
    var isFileType:Bool{
        let type = MessageType(rawValue: messageType ?? 0)
        switch type {
        case .VOICE,.PICTURE,.VIDEO,.SOUND,.FILE,.POD_SPACE_FILE,.POD_SPACE_PICTURE,.POD_SPACE_SOUND,.POD_SPACE_VOICE:
            return true
        default:
            return false
        }
    }
}
