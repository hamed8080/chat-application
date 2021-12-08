//
//  MessageRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct MessageRow: View{
    
    var message:Message
    @State private (set) var showActionSheet:Bool = false
    @State private (set) var showParticipants:Bool = false
    private var viewModel:ThreadViewModel
    private var isMe:Bool
        
    
    init(message: Message, viewModel:ThreadViewModel,isMeForPreView:Bool? = nil) {
        self.message = message
        self.viewModel = viewModel
        self.isMe = isMeForPreView ?? (message.ownerId == (Chat.sharedInstance.getCurrentUser()?.id ?? AppState.shared.user?.id))
    }
    
    var body: some View {
        if let type = MessageType(rawValue: message.messageType ?? 0){
            if let message = message as? UploadFileMessage{
                UploadMessageType(viewModel: viewModel, message: message)
            }else if type == .TEXT || type == .PICTURE || type == .POD_SPACE_PICTURE || type == .FILE || type == .POD_SPACE_FILE {
                TextMessageType(message: message, showActionSheet: showActionSheet, isMe: isMe, viewModel: viewModel)
            }else if type == .END_CALL || type == .START_CALL{
                CallMessageType(message: message, showActionSheet: showActionSheet, isMe: isMe, viewModel: viewModel)
            }
        }
    }
}

struct CallMessageType:View{
    
    var message: Message
    @State var showActionSheet:Bool = false
    var isMe:Bool
    var viewModel:ThreadViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let type = MessageType(rawValue: message.messageType ?? 0 )
        HStack(alignment:.center){
            if let time = message.time, let date = Date(milliseconds: Int64(time)){
                Text("Call \(type == .END_CALL ? "ended" : "started") at \(date.timeAgoSinceDate())")
                    .foregroundColor(Color.primary.opacity(0.8))
                    .font(.subheadline)
                    .padding(2)
            }
            
            Image(systemName: type == .START_CALL ?  "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(type == .START_CALL ? Color.green : Color.red)
        }
        .padding([.leading,.trailing])
        .background(colorScheme  == .light ? Color(CGColor(red: 0.718, green: 0.718, blue: 0.718, alpha:0.8)) : Color.gray.opacity(0.1))
        .cornerRadius(6)
        .frame(maxWidth:.infinity)
    }
}

struct TextMessageType:View{
    
    var message: Message
    @State var showActionSheet:Bool = false
    var isMe:Bool
    var viewModel:ThreadViewModel
    var body: some View {
        let type = MessageType(rawValue: message.messageType ?? 0)
        HStack{
            if isMe {
                Spacer()
            }
            Button(action: {}, label: {
                HStack{
                    VStack(alignment: .leading, spacing:8){
                        if type == .POD_SPACE_PICTURE || type == .PICTURE || type == .POD_SPACE_FILE || type == .FILE{
                            DownloadFileView(message: message)
                                .frame(width: 128, height: 128)
                        }
                        
                        Text((message.message?.isEmpty == true ? message.metaData?.name : message.message) ?? "")
                            .multilineTextAlignment(.trailing)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.black)
                        
                        HStack{
                            if let fileSize = message.metaData?.file?.size, let size = Int(fileSize){
                                Text(size.toSizeString)
                                    .multilineTextAlignment(.leading)
                                    .font(.subheadline)
                                    .foregroundColor(Color(named: "dark_green").opacity(0.8))
                            }
                            if let time = message.time, let date = Date(timeIntervalSince1970: TimeInterval(time)) {
                                Text("\(date.getTime())")
                                    .foregroundColor(Color(named: "dark_green").opacity(0.8))
                                    .font(.caption2.weight(.light))
                            }
                            
                            if isMe{
                                Image(uiImage: UIImage(named:  message.seen == true ? "double_checkmark" : "single_chekmark")!)
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(Color(named: "dark_green").opacity(0.8))
                                    .font(.caption2.weight(.light))
                            }
                        }
                    }
                }
                .frame(minWidth: 72, minHeight: 48, alignment: .center)
                .contentShape(Rectangle())
                .padding(8)
                .background(isMe ? Color(UIColor(named: "chat_me")!) : Color(UIColor(named:"chat_sender")!))
                .cornerRadius(12)
                
            })
                .onTapGesture {
                    print("on tap gesture")
                }.onLongPressGesture {
                    print("long press triggred")
                    showActionSheet.toggle()
                }
                .actionSheet(isPresented: $showActionSheet){
                    ActionSheet(title: Text("Manage Thread"), message: Text("you can mange thread here"), buttons: [
                        .cancel(Text("Cancel").foregroundColor(Color.red)),
                        .default(Text("Delete file from cache")){
                            viewModel.clearCacheFile(message: message)
                        },.default(Text((message.pinned ?? false) ? "UnPin" : "Pin")){
                            viewModel.pinUnpinMessage(message)
                        },
                        .default(Text("Delete")){
                            withAnimation {
                                viewModel.deleteMessage(message)
                            }
                        }
                    ])
                }
            
            if !isMe{
                Spacer()
            }
        }
    }
}


struct UploadMessageType:View{
    var viewModel:ThreadViewModel
    var message: UploadFileMessage
    
    var body: some View {
        
        HStack(alignment: .top){
            Spacer()
            HStack{
                UploadFileView(message:message, viewModel: viewModel,state: .UPLOADING)
                    .frame(width: 148, height: 148)
            }
            .contentShape(Rectangle())
            .frame(width: 128, height: 168)
            .background(Color(UIColor(named: "chat_me")!))
            .cornerRadius(12)
        }
    }
}


struct MessageRow_Previews: PreviewProvider {
    static var message:Message{
        let message = Message(threadId: 0,
                              id: 12,
                              message: "Hello",
                              messageType: 1,
                              seen: false,
                              time: 1636807773)
        return message
    }
    
    static var downloadMessage:Message{
        return Message(threadId: 0,
                       id: 12,
                       message: "Hello",
                       messageType: MessageType.FILE.rawValue,
                       time: 1636807773
        )
    }
    
    static var uploadMessage:UploadFileMessage{
        let msg = UploadFileMessage(uploadFileUrl: URL(string: "http://www.google.com")!, textMessage: "Test")
        msg.message = "Film.mp4"
        return msg
    }
    
    static var previews: some View {
        VStack{
            MessageRow(message: message,viewModel: ThreadViewModel(),isMeForPreView: false)
            MessageRow(message: message,viewModel: ThreadViewModel(),isMeForPreView: true)
            MessageRow(message: downloadMessage, viewModel: ThreadViewModel(),isMeForPreView: true)
            MessageRow(message: uploadMessage, viewModel: ThreadViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
