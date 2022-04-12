//
//  ThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct ThreadView:View {
    
    @StateObject var viewModel:ThreadViewModel
    
    @State
    var showThreadDetailButton = false
    
    @State
    var showAttachmentDialog: Bool = false
    
    @EnvironmentObject
    var appState:AppState
    
    @State
    var isInEditMode:Bool = false
    
    @State
    var showDeleteSelectedMessages:Bool = false
    
    @State
    var showSelectThreadToForward:Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View{
        ZStack{
            VStack{
                GeometryReader{ reader in
                    ScrollViewReader{ scrollView in
                        ZStack{
                            List(viewModel.model.messages , id:\.uniqueId) { message in
                                
                                MessageRow(message: message,viewModel: viewModel, isInEditMode: $isInEditMode)
                                    .onAppear {
                                        if viewModel.model.messages.last == message{
                                            viewModel.loadMore()
                                        }
                                        viewModel.sendSeenMessageIfNeeded(message)
                                    }
                                    .noSeparators()
                                    .listRowBackground(Color.clear)
                            }
                            .background(
                                ZStack{
                                    Image("chat_bg")
                                        .resizable(resizingMode: .tile)
                                        .renderingMode(.template)
                                        .opacity(colorScheme == .dark ? 0.9 : 0.25)
                                        .colorInvert()
                                        .colorMultiply(colorScheme == .dark ? Color.white : Color.cyan)
                                    let darkColors:[Color] = [.gray.opacity(0.5), .white.opacity(0.001)]
                                    let lightColors:[Color] = [.white.opacity(0.1), .gray.opacity(0.5)]
                                    LinearGradient(gradient: Gradient(colors:colorScheme == .dark ? darkColors : lightColors),
                                                   startPoint: .top,
                                                   endPoint: .bottom)
                                }
                            )
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                            .listStyle(PlainListStyle())
                            .onChange(of: viewModel.model.messages) { newValue in
                                withAnimation {
                                    if let index = viewModel.model.messages.firstIndex(where: {$0.uniqueId == viewModel.model.messages.last?.uniqueId}){
                                        scrollView.scrollTo(viewModel.model.messages[index].uniqueId, anchor: .top)
                                    }
                                }
                            }
                            
                            Button {
                                withAnimation {
                                    if let index = viewModel.model.messages.firstIndex(where: {$0.uniqueId == viewModel.model.messages.last?.uniqueId}){
                                        scrollView.scrollTo(viewModel.model.messages[index].uniqueId, anchor: .top)
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .resizable()
                                    .foregroundColor(Color.gray)
                                    .aspectRatio(contentMode: .fit)
                            }
                            .frame(width: 16, height: 16)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(24)
                            .position(x: reader.size.width - 24, y: reader.size.height - 36)
                            .contentShape(Rectangle())
                        }
                    }
                }.onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                }
                
                SendContainer(viewModel: viewModel,
                              showAttachmentDialog: $showAttachmentDialog,
                              showDeleteSelectedMessages: $showDeleteSelectedMessages,
                              showSelectThreadToForward: $showSelectThreadToForward
                )
                
                NavigationLink(destination: ThreadDetailView(viewModel: viewModel) , isActive: $showThreadDetailButton){
                    EmptyView()
                }
            }
            .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
            .toolbar{
                
                ToolbarItemGroup(placement:.navigationBarTrailing){
                    let thread = viewModel.model.thread
                    NavBarButton(showAvatarImage: true,
                                 avatarUrl: thread?.image,
                                 avatarUserName: thread?.title,
                                 avatarMetaData:thread?.metadata,
                                 action: {
                        showThreadDetailButton.toggle()
                    }
                    ).getNavBarItem().view
                }
                
                ToolbarItem(placement: .principal) {
                    VStack (alignment:.center){
                        
                        Text(viewModel.model.thread?.title ?? "")
                            .fixedSize()
                            .font(.headline)
                        
                        if let signalMessageText = viewModel.model.signalMessageText{
                            Text(signalMessageText)
                                .foregroundColor(Color(named: "text_color_blue"))
                                .font(.subheadline.bold())
                        }
                        
                        if let participantsCount = viewModel.model.thread?.participantCount{
                            Text("Members \(participantsCount)")
                                .fixedSize()
                                .foregroundColor(Color.gray)
                                .font(.footnote)
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .customAnimation(.default)
            .customDialog(isShowing: $showDeleteSelectedMessages, content: {
                PrimaryCustomDialog(title: "Delete selected messages",
                                    message: "Are you sure you want to delete all selected messages?",
                                    systemImageName: "trash.fill",
                                    hideDialog: $showDeleteSelectedMessages)
                { _ in
                    viewModel.deleteSelectedMessages()
                }
                .padding()
            })
            AttachmentDialog(showAttachmentDialog: $showAttachmentDialog,viewModel: ActionSheetViewModel(threadViewModel: viewModel))
        }
        .onChange(of: viewModel.model.isInEditMode) { newValue in
            isInEditMode = viewModel.model.isInEditMode
        }
        .onChange(of: viewModel.model.editMessage) { newValue in
            viewModel.textMessage = viewModel.model.editMessage?.message ?? ""
        }
        .onAppear{
            viewModel.getMessagesHistory()
            viewModel.setViewAppear(appear: true)
        }
        .onDisappear{
            viewModel.setViewAppear(appear: false)
        }
        .sheet(isPresented: $showSelectThreadToForward, onDismiss: nil, content: {
            SelectThreadContentList{ selectedThread in
                viewModel.sendForwardMessage(selectedThread)
            }
        })
    }
}

struct SendContainer:View{
    
    @StateObject var viewModel:ThreadViewModel
    
    @Binding
    var showAttachmentDialog: Bool
    
    @Binding
    var showDeleteSelectedMessages:Bool
    
    @Binding
    var showSelectThreadToForward:Bool
    
    var body: some View{
        let threadType = ThreadTypes(rawValue: viewModel.model.thread?.type ?? 0)
        
        if viewModel.model.isInEditMode{
            VStack{
                HStack{
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.blue)
                        .onTapGesture {
                            viewModel.setIsInEditMode(false)
                        }
                    
                    Text("\(viewModel.model.selectedMessages.count) selected \(viewModel.model.forwardMessage != nil ? "to forward" : "")")
                        .offset(x: 8)
                    Spacer()
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(named: "red_soft"))
                        .padding()
                        .onTapGesture {
                            showDeleteSelectedMessages.toggle()
                        }
                    
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.blue)
                        .padding()
                        .onTapGesture {
                            showSelectThreadToForward.toggle()
                        }
                }.padding(8)
                Divider()
            }
        }else{
            VStack{
                if let replyMessage = viewModel.model.replyMessage{
                    HStack{
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.blue)
                            .onTapGesture {
                                viewModel.setReplyMessage(nil)
                            }
                        Text(replyMessage.message ?? replyMessage.metaData?.name ?? "")
                            .offset(x: 8)
                            .onTapGesture {
                                //TODO: Go to reply message location
                            }
                        Spacer()
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.gray)
                    }.padding(8)
                    Divider()
                }
                
                HStack{
                    
                    Image(systemName: "paperclip")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray)
                        .onTapGesture {
                            showAttachmentDialog.toggle()
                        }
                    MultilineTextField(viewModel.textMessage == "" ? "Type message here ..." : "" ,text: $viewModel.textMessage, textColor: Color.black)
                        .cornerRadius(16)
                        .onChange(of: viewModel.textMessage) { newValue in
                            viewModel.textChanged(newValue)
                        }
                    let scale = viewModel.model.isRecording ? 1.8 : 1
                    Button {
                        //ignore
                    } label: {
                        Image(systemName: viewModel.model.isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.model.isRecording ? Color(named: "chat_me").opacity(0.9):  Color.gray)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded({ value in
                                viewModel.toggleRecording()
                            })
                    )
                    .offset(x: viewModel.model.isRecording ? -10 : 0 )
                    .scaleEffect(CGSize(width: scale, height: scale))
                    .gesture(
                        DragGesture(minimumDistance: 100).onEnded({ value in
                            if value.location.x < 0{
                                viewModel.toggleRecording()
                            }
                        })
                    )
                    .background(RecordAudioBackground(viewModel: viewModel,cornerRadius: 8))
                    if viewModel.model.isRecording == false{
                        Button {
                            viewModel.sendTextMessage(viewModel.textMessage)
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.blue)
                        }
                    }
                }
                .padding(8)
                .opacity(threadType == .CHANNEL ? 0.3 : 1.0)
                .disabled(threadType == .CHANNEL)
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    
    static var previews: some View {
        let vm = ThreadViewModel(thread: MockData.thread)
        ThreadView(viewModel: vm,showAttachmentDialog: false)
            .preferredColorScheme(.dark)
            .previewDevice("iPhone 13 Pro Max")
            .environmentObject(AppState.shared)
            .onAppear(){
                vm.setupPreview()
                //                vm.toggleRecording()
                //                vm.setReplyMessage(MessageRow_Previews.message)
                //                vm.setForwardMessage(MessageRow_Previews.message)
                vm.setIsInEditMode(false)
            }
    }
}
