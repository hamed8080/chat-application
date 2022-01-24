//
//  CallControlsContent.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK
import WebRTC

struct CallControlsContent: View {
    
    @StateObject
    var viewModel               :CallControlsViewModel
    
    @EnvironmentObject
    var callState:CallState
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle          :LocalStatusBarStyle
    
    @State
    var showCallParticipants:Bool = false
    
    @State
    var showDetailPanel:Bool = false
    
    @State
    var localView   = RTCVideoReperesentable()
    
    @State
    var remoteView  = RTCVideoReperesentable()
    
    @Environment(\.presentationMode) var presentationMode
    
    private let recoringIndicatorAnimation = Animation.easeInOut(duration: 1).repeatForever()
   
    @State
    var showRecordingIndicator: Bool = false

    var body: some View {
        GeometryReader{ reader in
            ZStack{
                if callState.model.isCallStarted  && callState.model.isVideoCall{
                     remoteView
                        .ignoresSafeArea()
                        .frame(width: reader.size.width , height: reader.size.height)
                        .background(Color.red)
                }
                
                VStack(){
                    Text("")
                        .padding(.bottom , 48)
                    
                    Text(callState.model.receiveCall?.creator.name?.uppercased() ?? callState.model.titleOfCalling.uppercased())
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                        .fontWeight(.heavy)
                        .padding(.bottom)
                    if callState.model.isCallStarted{
                        Text(callState.model.timerCallString ?? "")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        
                    }else{
                        Text(callState.model.receiveCall?.creator.name != nil ? "Ringing..." : "Calling...")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    if callState.model.receiveCall != nil && callState.model.isCallStarted == false{
                        HStack(spacing:32){
                            Spacer()
                            if callState.model.receiveCall?.type == .VIDEO_CALL{
                                CallControlItem(iconSfSymbolName: "video.fill", subtitle: "Answer", color: .green){
                                    viewModel.answerCall(video: true, audio: true)
                                }
                                Spacer()
                            }
                            
                            CallControlItem(iconSfSymbolName: "phone.fill", subtitle: "Answer", color: .green){
                                viewModel.answerCall(video: false, audio: true)
                            }
                            
                            Spacer()
                            
                            CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "Reject Call", color: .red){
                                viewModel.cancelCall()
                                withAnimation{
                                    callState.model.setShowCallView(false)
                                }
                            }
                            Spacer()
                        }
                        .frame(width: reader.size.width, height: 72)
                    }else{
                        //call started
                        if callState.model.isVideoCall {
                            HStack(){
                                localView
                                    .cornerRadius(12, antialiased: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                                    .frame(width: reader.size.width / 2 , height: 168)
                                    .onTapGesture {
                                        viewModel.switchCamera()
                                    }
                                    
                                Spacer()
                            }
                            .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 0))
                            .frame(height: 168)
                        }
                        
                        HStack(spacing:12){
                            
                            CallControlItem(iconSfSymbolName: "ellipsis", subtitle: "More", color: .gray){
                                withAnimation {
                                    showDetailPanel.toggle()
                                }
                            }
                            
                            CallControlItem(iconSfSymbolName: viewModel.model.isMute ? "mic.slash.fill" : "mic.fill"  , subtitle: "Mute", color: viewModel.model.isMute ? .gray : .green){
                                viewModel.toggleMute()
                            }
                            
                            CallControlItem(iconSfSymbolName: viewModel.model.isVideoOn ? "video.fill" : "video.slash.fill", subtitle: "Video", color: viewModel.model.isVideoOn ? .green : .gray){
                                viewModel.toggleVideo()
                            }
                            
                            CallControlItem(iconSfSymbolName: viewModel.model.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill", subtitle: "Speaker", color: viewModel.model.isSpeakerOn ? .green : .gray){
                                viewModel.toggleSpeaker()
                            }
                            
                            CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "End Call", color: .red){
                                viewModel.endCall()
                                withAnimation{
                                    callState.model.setShowCallView(false)
                                }
                            }
                        }
                        .frame(width: reader.size.width, height: 72)
                    }
                }
                .onAppear{
                    self.statusBarStyle.currentStyle = .lightContent
                    callState.setLocalVideoRenderer(localView.renderer)
                    callState.setRemoteVideoRenderer(remoteView.renderer)
                }
                .onDisappear{
                    self.statusBarStyle.currentStyle = .default
                }
                .background(getBackground())
                
                if showDetailPanel{
                    getMoreCallControlsView()
                }
                
                if callState.model.isRecording{
                    Image(systemName: "record.circle")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color.red)
                        .position(x: 32, y: 24)
                        .opacity(showRecordingIndicator ? 1 : 0)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .customAnimation(.default)
        .onAppear{
            viewModel.startRequestCallIfNeeded()
            withAnimation(recoringIndicatorAnimation){
                showRecordingIndicator.toggle()
            }
        }
        .onReceive(callState.$model , perform: { _ in
            if callState.model.showCallView == false{
                presentationMode.wrappedValue.dismiss()
            }
        })
    }
    
    @ViewBuilder
    func getBackground()->some View{
        if callState.model.isCallStarted && callState.model.isVideoCall == true {
            EmptyView()
        }else{
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(.all)
        }
    }
    
    @ViewBuilder
    func getMoreCallControlsView()->some View{
        SheetDialog(showAttachmentDialog: $showDetailPanel) {
            HStack{
                if callState.model.isVideoCall{
                    CallControlItem(iconSfSymbolName: "record.circle", subtitle: "Record", color: .red){
                        if callState.model.isRecording{
                            viewModel.stopRecording()
                        }else{
                            viewModel.startRecording()
                        }
                    }
                }
                
                if callState.model.isRecording{
                    Spacer()
                    Text(callState.model.recordingTimerString ?? "")
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.thinMaterial)
                        )
                }
            }
            
            CallControlItem(iconSfSymbolName: "person.fill.badge.plus", subtitle: "prticipants", color: .gray){
                withAnimation {
                    showCallParticipants.toggle()
                }
            }.sheet(isPresented: $showCallParticipants, content: {
                CallParticipantsContentList(callId: callState.model.startCall?.callId ?? 0)
            })
        }
        .layoutPriority(2)
        .frame(height:UIScreen.main.bounds.height)
        .ignoresSafeArea()
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
            VStack(spacing:4){
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
                    .shadow(color: .blue, radius: 1, x: 0, y: 0)
                    .fixedSize()
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
            .previewDevice("iPhone 13")
            .onAppear(){
                let participant = ParticipantRow_Previews.participant
                let receiveCall = CreateCall(type: .VIDEO_CALL, creatorId: 0, creator: participant, threadId: 0, callId: 0, group: false)
                callState.model.setReceiveCall(receiveCall)

                let clientDto   = ClientDTO(clientId: "", topicReceive: "", topicSend: "",userId: 0, desc: "", sendKey: "", video: true, mute: false)
                let chatDataDto = ChatDataDTO(sendMetaData: "", screenShare: "", reciveMetaData: "", turnAddress: "", brokerAddressWeb: "", kurentoAddress: "")
                let startedCall = StartCall(certificateFile: "", clientDTO: clientDto, chatDataDto: chatDataDto, callName: nil, callImage: nil)
                callState.model.setStartedCall(startedCall)
                callState.model.setIsRecording(isRecording: true)
                callState.model.setStartRecordingDate()
                callState.startRecordingTimer()
                viewModel.setupPreview()
            }
        
    }
}
