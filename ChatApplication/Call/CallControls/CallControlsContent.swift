//
//  CallControlsContent.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct CallControlsContent: View {
    
    @StateObject
    var viewModel               :CallControlsViewModel
    
    @EnvironmentObject
    var appState                :AppState
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle          :LocalStatusBarStyle
    
    var body: some View {
        GeometryReader{ reader in
            VStack(){
                
                Text("")
                    .padding(.bottom , 48)
                
                Text(appState.titleOfCalling.uppercased())
                    .foregroundColor(.white)
                    .font(.system(size: 22))
                    .fontWeight(.heavy)
                    .padding(.bottom)
                
                Text("Calling...")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing:32){
                    
                    CallControlItem(iconSfSymbolName: viewModel.model.isMute ? "mic.slash.fill" : "mic.fill"  , subtitle: "Mute", color: .gray){
                        viewModel.toggleMute()
                    }
                    
                    CallControlItem(iconSfSymbolName: viewModel.model.isVideoOn ? "video.fill" : "video.slash.fill", subtitle: "Video", color: .gray){
                        viewModel.toggleVideo()
                    }
                    
                    CallControlItem(iconSfSymbolName: viewModel.model.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill", subtitle: "Speaker", color: .gray){
                        //                            viewModel.setSpeaker()
                    }
                    
                    CallControlItem(iconSfSymbolName: "person.fill.badge.plus", subtitle: "prticipants", color: .gray){
                        //                            viewModel.addParticipant()
                    }
                    
                    CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "End Call", color: .red){
                        viewModel.endCall()
                        withAnimation{
                            appState.showCallView.toggle()
                        }
                    }
                }
                .padding(4)
                .frame(width: reader.size.width, height: 72)
            }
            .onAppear{
                self.statusBarStyle.currentStyle = .lightContent
            }
            .onDisappear{
                self.statusBarStyle.currentStyle = .default
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(.all)
            )
        }
        .onAppear{
            
            viewModel.satrtCallWithThreadId(37299)
//
//            if let threadId = appState.callThreadId{
//                viewModel.satrtCallWithThreadId(threadId)
//            }
//            else if appState.isP2PCalling{
//                viewModel.startP2PCall(appState.selectedContacts)
//            }else{
//                viewModel.startGroupCall(appState.selectedContacts)
//            }
        }
    }
}

struct CallControlItem:View {
    
    var iconSfSymbolName :String
    var subtitle         :String
    var color            :Color? = nil
    var action           :(()->Void)?
    
    @State var isActive = false
    
    var body : some View{
        Button(action: {
            isActive.toggle()
            action?()
        }, label: {
            VStack{
                Circle()
                    .fill(color ?? .blue)
                    .shadow(color: .blue, radius: 20, x: 0, y: 0)
                    .overlay(
                        Image(systemName:iconSfSymbolName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .padding(2)
                    )
                    .frame(width: 52, height: 52)
                Text(subtitle)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .font(.system(size:10 ))
            }
        })
    }
}


struct CallControlsView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        let viewModel = CallControlsViewModel()
        let appState = AppState()
        CallControlsContent(viewModel:viewModel)
            .environmentObject(appState)
            .onAppear(){
                viewModel.setupPreview()
            }
        
    }
}
