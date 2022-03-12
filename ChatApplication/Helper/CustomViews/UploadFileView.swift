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
    var uploadFile: UploadFile
    
    @State
    var percent:Double = 0
    
    private let viewModel:ThreadViewModel
    private let message:UploadFileMessage
    
    init(message:UploadFileMessage,viewModel:ThreadViewModel,state:UploadFileState? = nil) {
        self.viewModel = viewModel
        self.message = message
        self.message.message = viewModel.textMessage
        uploadFile = UploadFile(thread: viewModel.model.thread, fileUrl: message.uploadFileUrl, textMessage: message.message ?? "")
        uploadFile.startUpload()
        //only for preveiw
        if let state = state{
            uploadFile.state = state
        }
    }
    
    @ViewBuilder
    var body: some View{
        GeometryReader{ reader in            
            ZStack(alignment:.center){
                switch uploadFile.state{
                case .UPLOADING,.STARTED:
                    CircularProgressView(percent: $percent)
                        .padding()
                        .onTapGesture {
                            uploadFile.pauseUpload()
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
                            uploadFile.resumeUpload()
                        }
                default:
                    EmptyView()
                }
            }
            .onReceive(uploadFile.$state, perform: { state in
                if state == .COMPLETED{
                    viewModel.deleteMessageFromModel(message)
                }
            })
            .onReceive(uploadFile.uploadPercent) { percent in
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

class UploadFile: ObservableObject{
    
    private (set) var uploadPercent = PassthroughSubject<Double?,Never>()
    
    @Published
    var state:UploadFileState = .STARTED
    var fileUrl:URL
    var textMessage:String
    var thread:Conversation?
    var uploadUniqueId:String? = nil
    
    init(thread:Conversation?, fileUrl:URL, textMessage:String = ""){
        self.thread      = thread
        self.fileUrl     = fileUrl
        self.textMessage = textMessage
    }
    
    func startUpload(){
        state = .STARTED        
        guard let threadId = thread?.id, let data = try? Data(contentsOf: fileUrl) else {return}
        let message = NewSendTextMessageRequest(threadId: threadId, textMessage: textMessage, messageType: .POD_SPACE_FILE)
        
        let uploadFile = NewUploadFileRequest(data : data,
                                              fileExtension: ".\(fileUrl.fileExtension)",
                                              fileName: fileUrl.fileName,
                                              mimeType: fileUrl.mimeType,
                                              userGroupHash: thread?.userGroupHash)
        Chat.sharedInstance.sendFileMessage(textMessage:message, uploadFile: uploadFile){ uploadFileProgress ,error in
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
        UploadFileView(message: UploadFileMessage(uploadFileUrl: URL(string: "http://www.google.com")!),
                       viewModel: ThreadViewModel(thread: ThreadRow_Previews.thread), state: .UPLOADING)
            .background(Color.black.ignoresSafeArea())
    }
}

