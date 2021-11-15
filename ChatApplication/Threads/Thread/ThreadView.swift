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
    
    var body: some View{
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
                                }
                                .noSeparators()
                                .listRowBackground(Color.clear)
                        }
                        .background(
                            ZStack{
                                Image("chat_bg")
                                    .resizable(resizingMode: .tile)
                                    .opacity(0.25)
                                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9),
                                                                           Color.blue.opacity(0.6)]),
                                               startPoint: .top,
                                               endPoint: .bottom)
                            }
                        )
                        .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                        }
                        .listStyle(PlainListStyle())
                        .onChange(of: viewModel.model.messages) { newValue in
                            withAnimation {
                                scrollView.scrollTo(viewModel.model.messages.last?.id ?? 0)
                            }
                        }
                        
                        Button {
                            withAnimation {
                                scrollView.scrollTo(viewModel.model.messages.last?.id ?? 0 )
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
                    }
                }
            }
            
            SendContainer(message: "", viewModel: viewModel)
            NavigationLink(destination: ThreadDetailView(viewModel: viewModel) , isActive: $showThreadDetailButton){
                EmptyView()
            }
        }
        .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
        .navigationBarTitle(Text(viewModel.thread?.title ?? ""), displayMode: .inline)
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
                VStack {
                    
                    Text(viewModel.thread?.title ?? "")
                        .fixedSize()
                        .font(.headline)
                    
                    if let isTypingText = viewModel.model.isTypingText{
                        Text(isTypingText)
                            .fixedSize(horizontal: true, vertical: true)
                            .frame(width: 72,alignment:.leading)
                            .foregroundColor(Color.orange)
                            .font(.subheadline.bold())
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
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
    
    var body: some View{
        HStack{
            
            Image(systemName: "paperclip")
                .font(.system(size: 24))
                .foregroundColor(Color.gray)
            
            MultilineTextField("Type message here ...",text: $message)
                .cornerRadius(16)
                .onChange(of: message) { newValue in
                    viewModel.sendIsTyping()
                }
            
            Image(systemName: "mic")
                .font(.system(size: 24))
                .foregroundColor(Color.gray)
            
            Button {
                viewModel.sendTextMessage(message)
                message = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.blue)
            }
        }
        .padding(8)
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        ThreadView(viewModel: vm)
            .previewDevice("iPhone 13 Pro Max")
            .onAppear(){
                vm.setupPreview()
            }
    }
}
