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
    
    var isMe:Bool{
        return message.ownerId == Chat.sharedInstance.getCurrentUser()?.id
    }
    
    init(message: Message, viewModel:ThreadViewModel) {
        self.message = message
        self.viewModel = viewModel
    }
    
    var body: some View {
        if let type = MessageType(rawValue: message.messageType ?? 0){
            if type == .TEXT{
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
                .foregroundColor(type == .START_CALL ? Color.green  : Color.red)
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
        HStack{
            if isMe {
                Spacer()
            }
            
            Button(action: {}, label: {
                HStack{
                    VStack(alignment: .leading, spacing:8){
                        Text(message.message ?? "")
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                            .foregroundColor( isMe ? .white : .primary.opacity(0.8))
                        if let time = message.time, let date = Date(timeIntervalSince1970: TimeInterval(time)) {
                            Text("\(date.timeAgoSinceDate())")
                                .foregroundColor(isMe ? .white.opacity(0.9) : .primary.opacity(0.4))
                                .font(Font.caption2)
                        }
                    }
                    .frame(alignment: .leading)
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
                        .default(Text((message.pinned ?? false) ? "UnPin" : "Pin")){
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

struct MessageRow_Previews: PreviewProvider {
    static var message:Message{
        let message = Message(threadId: 0,
                              deletable: true,
                              delivered: true,
                              editable: true,
                              edited: true,
                              id: 12,
                              mentioned: false,
                              message: "Hello",
                              messageType: 1,
                              metadata: nil,
                              ownerId: nil,
                              pinned: true,
                              previousId: 0,
                              seen: true,
                              systemMetadata: nil,
                              time: 1636807773,
                              timeNanos: 0,
                              uniqueId: nil,
                              conversation: nil,
                              forwardInfo: nil,
                              participant: nil,
                              replyInfo: nil)
        return message
    }
    
    static var previews: some View {
        MessageRow(message: message,viewModel: ThreadViewModel())
            .preferredColorScheme(.dark)
    }
}
