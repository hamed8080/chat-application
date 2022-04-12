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
    
    @Binding
    var isInEditMode:Bool
    
    @State
    private var isSelected   = false
    
    init(message: Message, viewModel:ThreadViewModel,isInEditMode: Binding<Bool>,isMeForPreView:Bool? = nil) {
        self.message = message
        self.viewModel = viewModel
        self._isInEditMode = isInEditMode
        let cachedUserId = AppState.shared.user?.id
        self.isMe = isMeForPreView ?? (message.ownerId == (cachedUserId ?? Chat.sharedInstance.getCurrentUser()?.id ?? AppState.shared.user?.id))
    }
    
    var body: some View {
        HStack{
            if isInEditMode{
                Image(systemName: isSelected ? "checkmark.circle" : "circle")
                    .font(.title)
                    .frame(width: 22, height: 22, alignment: .center)
                    .foregroundColor(Color.blue)
                    .padding(24)
                    .onTapGesture {
                        isSelected.toggle()
                        viewModel.toggleSelectedMessage(message ,isSelected)
                    }
            }
            if let type = MessageType(rawValue: message.messageType ?? 0){
                if let message = message as? UploadFileMessage{
                    UploadMessageType(viewModel: viewModel, message: message)
                }else if type == .TEXT || type == .PICTURE || type == .POD_SPACE_PICTURE || type == .FILE || type == .POD_SPACE_FILE {
                    if isMe{
                        Spacer()
                    }
                    TextMessageType(message: message, showActionSheet: showActionSheet, isMe: isMe, viewModel: viewModel)
                                .frame(minWidth: 72, maxWidth: 420, minHeight: 48, alignment: .leading)
                }else if type == .END_CALL || type == .START_CALL{
                    CallMessageType(message: message, showActionSheet: showActionSheet, isMe: isMe, viewModel: viewModel)
                }
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
            VStack{
                if type == .POD_SPACE_PICTURE || type == .PICTURE || type == .POD_SPACE_FILE || type == .FILE{
                    DownloadFileView(message: message)
                        .frame(minHeight:128)
                }
                
                if let forwardInfo = message.forwardInfo{
                    ForwardMessageRow(forwardInfo: forwardInfo)
                }
                //TODO: TEXT must be alignment and image muset be fit
                Text((message.message?.isEmpty == true ? message.metaData?.name : message.message) ?? "")
                    .multilineTextAlignment(message.message?.isEnglishString == true ? .leading : .trailing)
                    .font(.body)
                    .foregroundColor(.black)
                HStack{
                    if let fileSize = message.metaData?.file?.size, let size = Int(fileSize){
                        Text(size.toSizeString)
                            .multilineTextAlignment(.leading)
                            .font(.subheadline)
                            .foregroundColor(Color(named: "dark_green").opacity(0.8))
                        Spacer()
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
            .contentShape(Rectangle())
            .padding(8)
            .background(isMe ? Color(UIColor(named: "chat_me")!) : Color(UIColor(named:"chat_sender")!))
            .cornerRadius(12)
            .onTapGesture {
                print("on tap gesture")
            }.onLongPressGesture {
                print("long press triggred")
                showActionSheet.toggle()
            }
        
            .contextMenu{
                
                Button (){
                    withAnimation {
                        viewModel.setReplyMessage(message)
                    }
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }
                
                Button (){
                    withAnimation {
                        viewModel.setForwardMessage(message)
                    }
                } label: {
                    Label("forward", systemImage: "arrowshape.turn.up.forward")
                }
                
                Button (){
                    withAnimation {
                        viewModel.setEditMessage(message)
                    }
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                
                if message.isFileType == true{
                    Button {
                        viewModel.clearCacheFile(message: message)
                    } label: {
                        Label("Delete file from cache", systemImage: "cylinder.split.1x2")
                    }
                }

                Button {
                    viewModel.pinUnpinMessage(message)
                } label: {
                    Label((message.pinned ?? false) ? "UnPin" : "Pin", systemImage: "pin")
                }
 
                Button{
                    withAnimation {
                        viewModel.setIsInEditMode(true)
                    }
                } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }
                
                Button (role:.destructive){
                    withAnimation {
                        viewModel.deleteMessage(message)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if !isMe{
                Spacer()
            }
        }
    }
}

struct ForwardMessageRow:View{
    
    var forwardInfo:ForwardInfo
    
    @State
    var showReadOnlyThreadView : Bool         = false
    
    var body: some View{
        VStack(alignment: .leading, spacing:0){
            HStack{
                if let name = forwardInfo.participant?.name{
                    Text(name)
                        .italic()
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                }
               
                Image(systemName: "arrowshape.turn.up.right")
                    .foregroundColor(Color.blue)
            }
            .frame(minHeight:20)
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 82)
                .frame(height:1)
                .padding([.top], 4)
        }.onTapGesture {
            showReadOnlyThreadView = true
        }
        if let forwardThread = forwardInfo.conversation{
            NavigationLink(destination: ThreadView(viewModel: ThreadViewModel(thread: forwardThread, readOnly: true)), isActive: $showReadOnlyThreadView){
                EmptyView()
            }
            .frame(width:0)
            .hidden()
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
                UploadFileView(uploadFile:UploadFile(thread: viewModel.model.thread,
                                                     fileUrl: message.uploadFileUrl,
                                                     textMessage: message.message ?? ""
                                                    ),
                               viewModel: viewModel,
                               message: UploadFileMessage(uploadFileUrl: message.uploadFileUrl)
                )
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
    
    
    static var previews: some View {
        List{
            let thread = MockData.thread
            MessageRow(message: MockData.message,viewModel:ThreadViewModel(thread: thread) , isInEditMode: .constant(true),isMeForPreView: false)
            MessageRow(message: MockData.forwardedMessage,viewModel:ThreadViewModel(thread: thread), isInEditMode: .constant(true),isMeForPreView: false)
            MessageRow(message: MockData.message,viewModel:ThreadViewModel(thread: thread), isInEditMode: .constant(true),isMeForPreView: true)
            MessageRow(message: MockData.downloadMessageSmallText, viewModel:ThreadViewModel(thread: thread), isInEditMode: .constant(true),isMeForPreView: true)
            MessageRow(message: MockData.downloadMessageLongText, viewModel:ThreadViewModel(thread: thread), isInEditMode: .constant(true),isMeForPreView: true)
            MessageRow(message: MockData.downloadPersianMessageLongText, viewModel:ThreadViewModel(thread: thread), isInEditMode: .constant(true),isMeForPreView: true)
            MessageRow(message: MockData.uploadMessage, viewModel: ThreadViewModel(thread: thread), isInEditMode: .constant(true))
        }
        .previewDevice("iPad Pro (12.9-inch) (5th generation)")
        .preferredColorScheme(.light)
        
    }
}
