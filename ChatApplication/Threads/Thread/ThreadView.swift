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
    
    var body: some View{
        ZStack{
            VStack{
                GeometryReader{ reader in
                    ScrollViewReader{ scrollView in
                        ZStack{
                            List(viewModel.model.messages , id:\.id) { message in
                                
                                MessageRow(message: message,viewModel: viewModel)
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
                                        .opacity(0.25)
                                        .colorMultiply( appState.dark ? Color.white : Color.black)
                                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9),
                                                                               Color.blue.opacity(0.6)]),
                                                   startPoint: .top,
                                                   endPoint: .bottom)
                                }
                            )
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                            .listStyle(PlainListStyle())
                            .onChange(of: viewModel.model.messages) { newValue in
                                withAnimation {
                                    if let index = viewModel.model.messages.firstIndex(where: {$0.id == viewModel.model.messages.last?.id}){
                                        scrollView.scrollTo(viewModel.model.messages[index].id, anchor: .top)
                                    }
                                }
                            }
                            
                            Button {
                                withAnimation {
                                    if let index = viewModel.model.messages.firstIndex(where: {$0.id == viewModel.model.messages.last?.id}){
                                        scrollView.scrollTo(viewModel.model.messages[index].id, anchor: .top)
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
                
                SendContainer(message: "", viewModel: viewModel,showAttachmentDialog: $showAttachmentDialog)
                NavigationLink(destination: ThreadDetailView(viewModel: viewModel) , isActive: $showThreadDetailButton){
                    EmptyView()
                }
            }
            .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
            .toolbar{
                
                ToolbarItemGroup(placement:.navigationBarTrailing){
                    let thread = viewModel.thread
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
                        
                        Text(viewModel.thread?.title ?? "")
                            .fixedSize()
                            .font(.headline)
                        
                        if let signalMessageText = viewModel.model.signalMessageText{
                            Text(signalMessageText)
                                .foregroundColor(Color(named: "text_color_blue"))
                                .font(.subheadline.bold())
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .animation(.default)
            AttachmentDialog(showAttachmentDialog: $showAttachmentDialog,viewModel: ActionSheetViewModel(threadViewModel: viewModel))
        }
        .onAppear{
            if let thread = AppState.shared.selectedThread{
                viewModel.setThread(thread: thread)
            }
            viewModel.setViewAppear(appear: true)
        }
        .onDisappear{
            viewModel.setViewAppear(appear: false)
        }
    }
}

struct SendContainer:View{
    
    @State
    var message:String
    
    @StateObject var viewModel:ThreadViewModel
    
    @Binding
    var showAttachmentDialog: Bool
    
    var body: some View{
        let threadType = ThreadTypes(rawValue: viewModel.thread?.type ?? 0)
        
        HStack{
            
            Image(systemName: "paperclip")
                .font(.system(size: 24))
                .foregroundColor(Color.gray)
                .onTapGesture {
                    showAttachmentDialog.toggle()
                }
            MultilineTextField("Type message here ...",text: $message)
                .cornerRadius(16)
                .onChange(of: message) { newValue in
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
                    viewModel.sendTextMessage(message)
                    message = ""
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

struct ThreadView_Previews: PreviewProvider {
    
    static var previews: some View {
        let vm = ThreadViewModel()
        ThreadView(viewModel: vm,showAttachmentDialog: false)
            .preferredColorScheme(.dark)
            .previewDevice("iPhone 13 Pro Max")
            .environmentObject(AppState.shared)
            .onAppear(){
                vm.setupPreview()
                vm.toggleRecording()
            }
    }
}
