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

    @Environment(\.isPreview) var isPreview
    
    @State
    var showMoreButton = false
    
    @State
    var showDatePicker = false
    
    @State
    var showExportFileURL = false
    
    var body: some View{
        ZStack{
            VStack{
                    ScrollViewReader{ scrollView in
                        ZStack{
                            GeometryReader{ reader in
                                List(viewModel.model.messages , id:\.uniqueId) { message in
                                    
                                    MessageRow(message: message,viewModel: viewModel, isInEditMode: $isInEditMode, proxy: reader)
                                        .onAppear {
                                            if viewModel.model.messages.last == message{
                                                viewModel.loadMore()
                                            }
                                            viewModel.sendSeenMessageIfNeeded(message)
                                        }
                                        .noSeparators()
                                        .listRowBackground(Color.clear)
                                }
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
                            .listStyle(.plain)
                            .onChange(of: viewModel.model.messages) { newValue in
                                withAnimation {
                                    if let index = viewModel.model.messages.firstIndex(where: {$0.uniqueId == viewModel.model.messages.last?.uniqueId}){
                                        scrollView.scrollTo(viewModel.model.messages[index].uniqueId, anchor: .top)
                                    }
                                }
                            }

//                            Button {
//                                withAnimation {
//                                    if let index = viewModel.model.messages.firstIndex(where: {$0.uniqueId == viewModel.model.messages.last?.uniqueId}){
//                                        scrollView.scrollTo(viewModel.model.messages[index].uniqueId, anchor: .top)
//                                    }
//                                }
//                            } label: {
//                                Image(systemName: "chevron.down")
//                                    .resizable()
//                                    .foregroundColor(Color.gray)
//                                    .aspectRatio(contentMode: .fit)
//                            }
//                            .frame(width: 16, height: 16)
//                            .padding(8)
//                            .background(Color.white)
//                            .cornerRadius(24)
//                            .position(x: reader.size.width - 24, y: reader.size.height - 36)
//                            .contentShape(Rectangle())
                        }
                    }
//                }
                .onTapGesture {
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
                    if let thread = viewModel.model.thread{
                        let token = isPreview ? "FAKE_TOKEN" : TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken
                        Avatar(
                            url:thread.image ,
                            userName: thread.inviter?.username?.uppercased(),
                            fileMetaData: thread.metadata,
                            imageSize: .MEDIUM,
                            style: .init(size: 36),
                            token: token,
                            previewImageName: thread.image ?? "avatar"
                        )
                        .onTapGesture {
                            showThreadDetailButton.toggle()
                        }
                        .cornerRadius(18)
                    }
                    
                    Menu {
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            Label {
                                Text("Export")
                            } icon: {
                                Image(systemName: "square.and.arrow.up")
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
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
                        
                        if viewModel.connectionStatus != .CONNECTED{
                            Text("\(viewModel.connectionStatus.stringValue) ...")
                                .foregroundColor(Color(named: "text_color_blue"))
                                .font(.subheadline.bold())
                        }                        
                    }
                }
            }
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
            
            if showDatePicker{
                DateSelectionView(){ startDate, endDate in
                    showDatePicker.toggle()
                    viewModel.exportChats(startDate: startDate, endDate: endDate)
                }
            }
        }
        .onChange(of: viewModel.model.isInEditMode) { newValue in
            isInEditMode = viewModel.model.isInEditMode
        }
        .onChange(of: viewModel.model.editMessage) { newValue in
            viewModel.textMessage = viewModel.model.editMessage?.message ?? ""
        }
        .onChange(of:  viewModel.model.showExportView){ newValue in
            showExportFileURL = newValue == true
        }
        .onAppear{
            if isPreview{
                viewModel.setupPreview()
            }
            viewModel.getMessagesHistory()
            viewModel.setViewAppear(appear: true)
        }
        .onDisappear{
            viewModel.setViewAppear(appear: false)
        }
        .sheet(isPresented: $showExportFileURL,onDismiss: {
            viewModel.hideExportView()
        }, content: {
            if let exportFileUrl = viewModel.model.exportFileUrl{
                ActivityViewControllerWrapper(activityItems: [exportFileUrl])
            }else{
                EmptyView()
            }
        })
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
            .preferredColorScheme(.light)
            .previewDevice("iPad Pro (12.9-inch) (5th generation)")
            .environmentObject(AppState.shared)
            .onAppear(){
//                                vm.toggleRecording()
//                                vm.setReplyMessage(MockData.message)
//                                vm.setForwardMessage(MockData.message)
                vm.setIsInEditMode(false)
            }
    }
}
