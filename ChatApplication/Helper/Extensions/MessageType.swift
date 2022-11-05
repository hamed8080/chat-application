//
//  MessageType.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/1/21.
//

import FanapPodChatSDK

extension Message{
    
    var iconName:String{
        switch messageType {
        case .text:
            return "doc.text.fill"
        case .voice:
            return "play.circle.fill"
        case .picture:
            return "photo.on.rectangle.angled"
        case .video:
            return "play.rectangle.fill"
        case .sound:
            return "play.circle.fill"
        case .file:
            return fileExtIcon
        case .podSpacePicture:
            return "photo.on.rectangle.angled"
        case .podSpaceVideo:
            return "play.rectangle.fill"
        case .podSpaceSound:
            return "play.circle.fill"
        case .podSpaceVoice:
            return "play.circle.fill"
        case .podSpaceFile:
            return fileExtIcon
        case .link:
            return "link.circle.fill"
        case .endCall:
            return "phone.fill.arrow.down.left"
        case .startCall:
            return "phone.fill.arrow.up.right"
        case .sticker:
            return "face.smiling.fill"
        case .location:
            return "map.fill"
        case .none:
            return "paperclip.circle.fill"
        case .some(.unknown):
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
        switch messageType {
        case .voice,.picture,.video,.sound,.file,.podSpaceFile,.podSpacePicture,.podSpaceSound,.podSpaceVoice:
            return true
        default:
            return false
        }
    }
}
