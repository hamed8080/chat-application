//
//  UploadFileView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import CoreMedia
import SwiftUI
import ChatAppViewModels
import ChatModels
import ChatCore
import ChatAppModels
import ChatDTO

public struct UploadFileView: View {
    @StateObject var viewModel = UploadFileViewModel()
    @State var percent: Int64 = 0
    @EnvironmentObject var threadViewModel: ThreadViewModel
    let message: Message

    public init(percent: Int64 = 0, message: Message) {
        self.percent = percent
        self.message = message
    }

    @ViewBuilder public var body: some View {
        HStack {
            ZStack(alignment: .center) {
                switch viewModel.state {
                case .UPLOADING, .STARTED:
                    CircularProgressView(percent: $percent, config: .normal)
                        .padding()
                        .frame(maxWidth: 128)
                        .onTapGesture {
                            viewModel.pauseUpload()
                        }
                case .PAUSED:
                    Image(systemName: "pause.circle")
                        .resizable()
                        .padding()
                        .font(.headline.weight(.thin))
                        .foregroundColor(.indigo)
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .frame(maxWidth: 128)
                        .onTapGesture {
                            viewModel.resumeUpload()
                        }
                default:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: viewModel.state)
        .animation(.easeInOut, value: percent)
        .onAppear {
            if (message.isImage) {
                viewModel.startUploadImage(message: message, thread: threadViewModel.thread)
            } else {
                viewModel.startUploadFile(message: message, thread: threadViewModel.thread)
            }
        }
        .onReceive(viewModel.$state) { state in
            if state == .COMPLETED {
                threadViewModel.onDeleteMessage(ChatResponse(uniqueId: message.uniqueId))
            }
        }
        .onReceive(viewModel.$uploadPercent) { percent in
            DispatchQueue.main.async {
                self.percent = percent
            }
        }
    }
}

struct UploadFileView_Previews: PreviewProvider {
    static var previews: some View {
        let message = UploadFileWithTextMessage(uploadFileRequest: UploadFileRequest(data: Data()), thread: MockData.thread)
        let threadViewModel = ThreadViewModel(thread: Conversation())
        let uploadFileVM = UploadFileViewModel()
        UploadFileView(message: message)
            .environmentObject(threadViewModel)
            .environmentObject(uploadFileVM)
            .background(Color.black.ignoresSafeArea())
            .onAppear {
                uploadFileVM.startUploadFile(message: message, thread: threadViewModel.thread)
            }
    }
}
