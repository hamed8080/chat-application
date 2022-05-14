//
//  UploadFileView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK
import Combine
import CoreMedia

struct UploadFileView :View{
    
    @ObservedObject
    var viewModel: UploadFileViewModel
    
    @State
    var percent:Double = 0
    
    let threadViewModel:ThreadViewModel
    let message:UploadFileMessage
    
    init(_ threadViewModel:ThreadViewModel, message:UploadFileMessage){
        self.message = message
        self.threadViewModel = threadViewModel
        self.viewModel = UploadFileViewModel(message:message, thread: threadViewModel.model.thread)
    }
    
    @ViewBuilder
    var body: some View{
        GeometryReader{ reader in
            ZStack(alignment:.center){
                switch viewModel.state{
                case .UPLOADING,.STARTED:
                    CircularProgressView(percent: $percent)
                        .padding()
                        .onTapGesture {
                            viewModel.pauseUpload()
                        }
                case .PAUSED:
                    Image(systemName: "pause.circle")
                        .resizable()
                        .font(.headline.weight(.thin))
                        .padding(32)
                        .position(x: reader.size.width / 2, y: reader.size.height / 2)
                        .foregroundColor(Color.white)
                        .scaledToFit()
                        .onTapGesture {
                            viewModel.resumeUpload()
                        }
                default:
                    EmptyView()
                }
            }
            .onAppear(perform: {
                viewModel.startUpload()
            })
            .onReceive(viewModel.$state, perform: { state in
                if state == .COMPLETED{
                    threadViewModel.deleteMessageFromModel(message)
                }
            })
            .onReceive(viewModel.uploadPercent) { percent in
                DispatchQueue.main.async {
                    if let percent = percent{
                        self.percent = percent
                    }
                }
            }
        }
    }
}

enum UploadFileState{
    case STARTED
    case COMPLETED
    case UPLOADING
    case PAUSED
    case ERROR
}

class UploadFileViewModel: ObservableObject{
    
    private (set) var uploadPercent = PassthroughSubject<Double?,Never>()
    
    @Published
    var state             :UploadFileState = .STARTED
    var message           :UploadFileMessage
    var thread            :Conversation?
    var uploadUniqueId    :String?         = nil
    
    init(message:UploadFileMessage, thread:Conversation?){
        self.message           = message
        self.thread            = thread
    }
    
    func startUpload(){
        state = .STARTED
        guard let threadId = thread?.id else{return}
        let textMessageType:MessageType = message.uploadFileRequest is UploadImageRequest ? .POD_SPACE_PICTURE : .POD_SPACE_FILE
        let message = SendTextMessageRequest(threadId: threadId, textMessage: self.message.message ?? "", messageType:  textMessageType)
        uploadFile(message , self.message.uploadFileRequest)
    }
    
    func uploadFile(_ message:SendTextMessageRequest, _ uploadFileRequest:UploadFileRequest){
        Chat.sharedInstance.sendFileMessage(textMessage:message, uploadFile: uploadFileRequest){ uploadFileProgress ,error in
            self.uploadPercent.send(Double(uploadFileProgress?.percent ?? 0))
        }onSent: { sentResponse, uniqueId, error in
            print(sentResponse ?? "")
            if error == nil{
                self.state = .COMPLETED
            }
        }onSeen: { seenResponse, uniqueId, error in
            print(seenResponse ?? "")
        }onDeliver: { deliverResponse, uniqueId, error in
            print(deliverResponse ?? "")
        }uploadUniqueIdResult:{ uploadUniqueId in
            self.uploadUniqueId = uploadUniqueId
        }messageUniqueIdResult:{ messageUniqueId in
           print(messageUniqueId)
        }
    }
    
    func pauseUpload(){
        guard let uploadUniqueId = uploadUniqueId else {return}
        Chat.sharedInstance.manageUpload(uniqueId: uploadUniqueId, action: .suspend, isImage: true){ statusString, susccessAction in
            self.state = .PAUSED
        }
    }
    
    func resumeUpload(){
        guard let uploadUniqueId = uploadUniqueId else {return}
        Chat.sharedInstance.manageUpload(uniqueId: uploadUniqueId, action: .resume, isImage: true){ statusString, susccessAction in
            self.state = .UPLOADING
        }
    }
}

struct UploadFileView_Previews: PreviewProvider {
    
    static var previews: some View {
        let threadViewModel = ThreadViewModel(thread: MockData.thread)
        UploadFileView(threadViewModel, message: UploadFileMessage(uploadFileRequest: UploadFileRequest(data: Data())))
            .background(Color.black.ignoresSafeArea())
    }
}

