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
    var callState:CallState
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle          :LocalStatusBarStyle
    
    @State
    var showCallParticipants:Bool = false
    
    var body: some View {
        GeometryReader{ reader in
            VStack(){
                
                Text("")
                    .padding(.bottom , 48)
                
                Text(callState.receiveCall?.creator.name?.uppercased() ?? callState.titleOfCalling.uppercased())
                    .foregroundColor(.white)
                    .font(.system(size: 22))
                    .fontWeight(.heavy)
                    .padding(.bottom)
                if callState.isCallStarted{
                    Text(callState.timerCallString ?? "")
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    
                }else{
                    Text(callState.receiveCall?.creator.name != nil ? "Ringing..." : "Calling...")
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if callState.receiveCall != nil{
                    HStack(spacing:32){
                        
                        CallControlItem(iconSfSymbolName: "phone.fill", subtitle: "Answer", color: .green){
                            viewModel.answerCall()
                        }
                        
                        Spacer()
                        
                        CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "Reject Call", color: .red){
                            viewModel.rejectCall()
                            withAnimation{
                                callState.showCallView.toggle()
                            }
                        }
                    }
                    .padding(64)
                    .frame(width: reader.size.width, height: 72)
                }else{
                    HStack(spacing:32){
                        
                        CallControlItem(iconSfSymbolName: viewModel.model.isMute ? "mic.slash.fill" : "mic.fill"  , subtitle: "Mute", color: viewModel.model.isMute ? .gray : .green){
                            viewModel.toggleMute()
                        }
                        
                        CallControlItem(iconSfSymbolName: viewModel.model.isVideoOn ? "video.fill" : "video.slash.fill", subtitle: "Video", color: viewModel.model.isVideoOn ? .green : .gray){
                            viewModel.toggleVideo()
                        }
                        
                        CallControlItem(iconSfSymbolName: viewModel.model.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill", subtitle: "Speaker", color: .gray){
                            viewModel.toggleSpeaker()
                        }
                        
                        CallControlItem(iconSfSymbolName: "person.fill.badge.plus", subtitle: "prticipants", color: .gray){
                            withAnimation {
                                showCallParticipants.toggle()
                            }
                        }.sheet(isPresented: $showCallParticipants, content: {
                            CallParticipantsContentList(callId: callState.startCall?.callId ?? 0)
                        })
                        
                        CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "End Call", color: .red){
                            viewModel.endCall()
                            withAnimation{
                                callState.showCallView.toggle()
                            }
                        }
                    }
                    .padding(4)
                    .frame(width: reader.size.width, height: 72)
                }
                
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
            viewModel.startRequestCallIfNeeded()
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
        let appState = AppState.shared
        let callState = CallState.shared
        
        CallControlsContent(viewModel:viewModel)
            .environmentObject(appState)
            .environmentObject(callState)
            .onAppear(){
//                let participant = ParticipantRow_Previews.participant
//                callState.receiveCall = CreateCall(type: .VOICE_CALL, creatorId: 0, creator: participant, threadId: 0, callId: 0, group: false)
                viewModel.setupPreview()
            }
        
    }
}
