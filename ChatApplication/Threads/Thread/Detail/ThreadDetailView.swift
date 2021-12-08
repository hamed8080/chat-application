//
//  ThreadDetailView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct ThreadDetailView:View {
    
    @StateObject var viewModel:ThreadViewModel
    
    @EnvironmentObject
    var callState:CallState
    
    @StateObject
    private var participantsVM:ParticipantsViewModel = ParticipantsViewModel()
    
    var body: some View{
        
        let thread = viewModel.thread
        
        GeometryReader{ reader in
            VStack{
                List{
                    VStack{
                        Avatar(url: thread?.image, userName: thread?.title?.uppercased() ,fileMetaData:thread?.metadata,style: .init(size: 128 ,textSize: 48))
                        Text(thread?.title ?? "")
                            .font(.headline.bold())
                        if let lastSeen =  ContactRow.getDate(notSeenDuration: thread?.participants?.first?.notSeenDuration){
                            Text(lastSeen)
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        HStack{
                            Spacer()
                            ActionButton(iconSfSymbolName: "bell", iconColor: .blue , taped:{
                                viewModel.muteUnMute()
                            })
                            
                            ActionButton(iconSfSymbolName: "magnifyingglass", iconColor: .blue , taped:{
                                viewModel.searchInsideThreadMessages("")
                            })
                            
                            if let type = thread?.type, ThreadTypes(rawValue: type) == .NORMAL{
                                ActionButton(iconSfSymbolName: "video",height: 16,taped:{
                                    callState.model.setIsVideoCallRequest(true)
                                    callState.model.setIsP2PCalling(true)
                                    callState.model.setSelectedThread(thread)
                                    withAnimation(.spring()){
                                        callState.model.setShowCallView(true)
                                    }
                                })
                                
                                ActionButton(iconSfSymbolName: "phone", taped:{
                                    callState.model.setIsP2PCalling(true)
                                    callState.model.setSelectedThread(thread)
                                    withAnimation(.spring()){
                                        callState.model.setShowCallView(true)
                                    }
                                })
                                
                                ActionButton(iconSfSymbolName: "hand.raised.slash", iconColor: .blue , taped:{
                                    //                                    viewModel.blockOrUnBlock(contact)
                                })
                            }
                            Spacer()
                        }
                        .padding(SwiftUI.EdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8))
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(16)
                    }
                    .noSeparators()
                    
                    if let type = thread?.type, ThreadTypes(rawValue: type) != .NORMAL{
                        Section(content: {
                            ForEach(participantsVM.model.participants , id:\.id) { participant in
                                ParticipantRow(participant: participant, style: .init(avatarConfig: .init(size: 32, textSize: 16), textFont: .headline))
                                    .onAppear {
                                        if participantsVM.model.participants.last == participant{
                                            participantsVM.loadMore()
                                        }
                                    }
                            }
                        }, header: {
                            Text("Members")
                                .font(.headline.bold())
                                .foregroundColor(Color.primary)
                        })
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .ignoresSafeArea()
        .navigationViewStyle(.stack)
        .onAppear{
            participantsVM.threadId = thread?.id ?? 0
            participantsVM.getParticipantsIfConnected()
            if let thread = AppState.shared.selectedThread{
                viewModel.setThread(thread: thread)
            }
        }
    }
    
}

struct ThreadDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        ThreadDetailView(viewModel: vm)
            .environmentObject(AppState.shared)
            .previewDevice("iPhone 13 Pro Max")
            .onAppear(){
                vm.setupPreview()
            }
    }
}
