//
//  UploadMessageImageView.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import CoreMedia
import SwiftUI
import TalkViewModels
import ChatModels
import ChatCore
import TalkModels
import ChatDTO
import TalkUI

public struct UploadMessageImageView: View {
    let viewModel: MessageRowViewModel
    var message: Message { viewModel.message }

    public var body: some View {
        ZStack {
            if let data = message.uploadFile?.uploadImageRequest?.dataToSend, let image = UIImage(data: data) {
                /// We use max to at least have a width, because there are times that maxWidth is nil.
                let width = max(128, (ThreadViewModel.maxAllowedWidth)) - (8 + MessageRowBackground.tailSize.width)
                /// We use max to at least have a width, because there are times that maxWidth is nil.
                /// We use min to prevent the image gets bigger than 320 if it's bigger.
                let height = min(320, max(128, (ThreadViewModel.maxAllowedWidth)))
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .blur(radius: 16, opaque: false)
                    .clipped()
                    .zIndex(0)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
            }
            OverladUploadImageButton(messageRowVM: viewModel)
                .environmentObject(viewModel.uploadViewModel!)
        }
        .onTapGesture {
            if viewModel.uploadViewModel?.state == .paused {
                viewModel.uploadViewModel?.resumeUpload()
            } else if viewModel.uploadViewModel?.state == .uploading {
                viewModel.uploadViewModel?.pauseUpload()
            }
        }
        .task {
            viewModel.uploadViewModel?.startUploadImage()
        }
    }
}

struct OverladUploadImageButton: View {
    let messageRowVM: MessageRowViewModel
    @EnvironmentObject var viewModel: UploadFileViewModel
    var message: Message { messageRowVM.message }
    var percent: Int64 { viewModel.uploadPercent }
    var stateIcon: String {
        if viewModel.state == .uploading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.up"
        }
    }

    var body: some View {
        if viewModel.state != .completed {
            HStack {
                ZStack {
                    Image(systemName: stateIcon)
                        .resizable()
                        .scaledToFit()
                        .font(.system(size: 8, design: .rounded).bold())
                        .frame(width: 8, height: 8)
                        .foregroundStyle(Color.App.text)

                    Circle()
                        .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.App.white)
                        .rotationEffect(Angle(degrees: 270))
                        .frame(width: 18, height: 18)
                }
                .frame(width: 26, height: 26)
                .background(Color.App.white.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius:(13)))

                let uploadFileSize: Int64 = Int64((message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
                let realServerFileSize = message.fileMetaData?.file?.size
                if let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale) {
                    Text(fileSize)
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldCaption2)
                        .foregroundColor(Color.App.text)
                }
            }
            .frame(height: 30)
            .frame(minWidth: 76)
            .padding(4)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius:(18)))
            .animation(.easeInOut, value: stateIcon)
            .animation(.easeInOut, value: percent)
        }
    }
}

struct UploadMessageImageView_Previews: PreviewProvider {
    static var previews: some View {
        let message = UploadFileWithTextMessage(uploadFileRequest: UploadFileRequest(data: Data()), thread: MockData.thread)
        let messageViewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        let uploadFileVM = UploadFileViewModel(message: message)
        UploadMessageImageView(viewModel: messageViewModel)
            .environmentObject(uploadFileVM)
            .background(Color.black.ignoresSafeArea())
            .onAppear {
                uploadFileVM.startUploadFile()
            }
    }
}
