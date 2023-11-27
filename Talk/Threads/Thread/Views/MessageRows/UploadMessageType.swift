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
    @EnvironmentObject var viewModel: MessageRowViewModel
    var message: Message { viewModel.message }

    var body: some View {
        if message.isUploadMessage {
            if message.isUnsentMessage == false, message.uploadFile?.uploadImageRequest != nil {
                UploadMessageImageView(viewModel: viewModel)
            } else if message.isUnsentMessage == false, message.uploadFile?.uploadFileRequest != nil {
                UploadMessageFileView(viewModel: viewModel)
            }
        }
    }
}
