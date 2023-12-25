//
//  UploadMessageFileView.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import SwiftUI
import TalkViewModels
import ChatModels
import TalkModels
import ChatDTO
import TalkUI

public struct UploadMessageFileView: View {
    let viewModel: MessageRowViewModel
    var message: Message { viewModel.message }

    public var body: some View {
        HStack(spacing: 4) {
            UploadImageButton(messageRowVM: viewModel)
                .environmentObject(viewModel.uploadViewModel!)
            if let fileName = message.fileName ?? viewModel.fileMetaData?.file?.originalName {
                Text("\(fileName)\(message.fileExtension ?? "")")
                    .foregroundStyle(Color.App.text)
                    .font(.iransansBoldCaption)
            }
        }
        .task {
            viewModel.uploadViewModel?.startUploadFile()
        }
    }
}

struct UploadImageButton: View {
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
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.App.bgPrimary)

                    Circle()
                        .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.App.bgPrimary)
                        .rotationEffect(Angle(degrees: 270))
                        .frame(width: 32, height: 32)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .frame(width: 42, height: 42)
                .background(Color.App.btnDownload)
                .clipShape(RoundedRectangle(cornerRadius:(42 / 2)))
                .onTapGesture {
                    if viewModel.state == .paused {
                        viewModel.resumeUpload()
                    } else if viewModel.state == .uploading {
                        viewModel.pauseUpload()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    if let fileZize = messageRowVM.fileMetaData?.file?.size {
                        Text(String(fileZize))
                            .multilineTextAlignment(.leading)
                            .font(.iransansBoldCaption2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct UploadMessageFileView_Previews: PreviewProvider {
    static var previews: some View {
        let message = UploadFileWithTextMessage(uploadFileRequest: UploadFileRequest(data: Data()), thread: MockData.thread)
        let messageViewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        let uploadFileVM = UploadFileViewModel(message: message)
        UploadMessageFileView(viewModel: messageViewModel)
            .environmentObject(uploadFileVM)
            .background(Color.black.ignoresSafeArea())
            .onAppear {
                uploadFileVM.startUploadFile()
            }
    }
}
