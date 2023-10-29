//
//  UploadMessageType.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct UploadMessageType: View {
    var message: Message
    @EnvironmentObject var threadViewModel: ThreadViewModel

    var body: some View {
        VStack(spacing: 8) {
            if message.isUnsentMessage == false {
                UploadFileView(message: message)
                    .environmentObject(threadViewModel)
            } else if let data = message.uploadFile?.uploadFileRequest.data {
                // Show cache version image if the sent was failed.
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320)
                } else if let iconName = message.iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .scaledToFit()
                        .padding()
                        .foregroundColor(Color.App.primary)
                }
            }
        }
    }
}
