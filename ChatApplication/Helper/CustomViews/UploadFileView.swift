//
//  UploadFileView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import CoreMedia
import FanapPodChatSDK
import SwiftUI

struct UploadFileView: View {
    @StateObject var viewModel = UploadFileViewModel()
    @State var percent: Int64 = 0
    @EnvironmentObject var threadViewModel: ThreadViewModel
    let message: Message

    @ViewBuilder var body: some View {
        HStack {
            ZStack(alignment: .center) {
                switch viewModel.state {
                case .UPLOADING, .STARTED:
                    CircularProgressView(percent: $percent)
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
            viewModel.startUpload(message: message, thread: threadViewModel.thread)
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

enum UploadFileState {
    case STARTED
    case COMPLETED
    case UPLOADING
    case PAUSED
    case ERROR
}

class UploadFileViewModel: ObservableObject {
    @Published private(set) var uploadPercent: Int64 = 0
    @Published var state: UploadFileState = .STARTED
    var message: Message?
    var uploadFileWithTextMessage: UploadWithTextMessageProtocol { message as! UploadWithTextMessageProtocol }
    var thread: Conversation?
    var uploadUniqueId: String?

    init() {}

    func startUpload(message: Message, thread: Conversation?) {
        self.message = message
        self.thread = thread
        state = .STARTED
        guard let threadId = thread?.id else { return }
        let textMessageType: MessageType = uploadFileWithTextMessage.uploadFileRequest is UploadImageRequest ? .podSpacePicture : .podSpaceFile
        let message = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        uploadFile(message, uploadFileWithTextMessage.uploadFileRequest)
    }

    func uploadFile(_ message: SendTextMessageRequest, _ uploadFileRequest: UploadFileRequest) {
        ChatManager.activeInstance?.sendFileMessage(textMessage: message, uploadFile: uploadFileRequest) { uploadFileProgress, _ in
            self.uploadPercent = uploadFileProgress?.percent ?? 0
        } onSent: { response in
            print(response.result ?? "")
            if response.error == nil {
                self.state = .COMPLETED
            }
        } onSeen: { response in
            print(response.result ?? "")
        } onDeliver: { response in
            print(response.result ?? "")
        } uploadUniqueIdResult: { uploadUniqueId in
            self.uploadUniqueId = uploadUniqueId
        } messageUniqueIdResult: { messageUniqueId in
            print(messageUniqueId)
        }
    }

    func pauseUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        ChatManager.activeInstance?.manageUpload(uniqueId: uploadUniqueId, action: .suspend) { _, _ in
            self.state = .PAUSED
        }
    }

    func resumeUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        ChatManager.activeInstance?.manageUpload(uniqueId: uploadUniqueId, action: .resume) { _, _ in
            self.state = .UPLOADING
        }
    }
}

struct UploadFileView_Previews: PreviewProvider {
    static var previews: some View {
        let message = UploadFileWithTextMessage(uploadFileRequest: UploadFileRequest(data: Data()), thread: MockData.thread)
        let threadViewModel = ThreadViewModel()
        let uploadFileVM = UploadFileViewModel()
        UploadFileView(message: message)
            .environmentObject(threadViewModel)
            .environmentObject(uploadFileVM)
            .background(Color.black.ignoresSafeArea())
            .onAppear {
                uploadFileVM.startUpload(message: message, thread: threadViewModel.thread)
                threadViewModel.setup(thread: MockData.thread)
            }
    }
}
