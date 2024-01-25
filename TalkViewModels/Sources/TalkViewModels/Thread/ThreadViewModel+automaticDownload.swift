//
//  ThreadViewModel+automaticDownload.swift
//  
//
//  Created by hamed on 11/14/23.
//

import Foundation

extension ThreadViewModel {
    func canDownloadImagesInConversation() -> Bool {
        let type = thread.type
        let globalDownload = model.automaticDownloadSettings.downloadImages
        if type == .channel || type == .channelGroup, globalDownload && model.automaticDownloadSettings.channel.downloadImages {
            return true
        } else if (type == .ownerGroup || type == .publicGroup) && thread.group == true, globalDownload && model.automaticDownloadSettings.group.downloadImages {
            return true
        } else if type == .normal || (thread.group == false || thread.group == nil), globalDownload && model.automaticDownloadSettings.privateChat.downloadImages {
            return true
        } else {
            return false
        }
    }

    func canDownloadFilesInConversation() -> Bool {
        let type = thread.type
        let globalDownload = model.automaticDownloadSettings.downloadFiles
        if type?.isChannelType == true, globalDownload && model.automaticDownloadSettings.channel.downloadFiles {
            return true
        } else if (type == .ownerGroup || type == .publicGroup) && thread.group == true, globalDownload && model.automaticDownloadSettings.group.downloadImages {
            return true
        } else if type == .normal || (thread.group == false || thread.group == nil), globalDownload && model.automaticDownloadSettings.privateChat.downloadFiles {
            return true
        } else {
            return false
        }
    }
}
