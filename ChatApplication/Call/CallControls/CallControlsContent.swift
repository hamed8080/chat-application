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
    
    @Environment(\.presentationMode) var presentationMode
    
    private let recoringIndicatorAnimation = Animation.easeInOut(duration: 1).repeatForever()
    
    @State
    var showRecordingIndicator: Bool = false
    
    @State
    var showToast = false
    
    var gridColumns:[GridItem]{
        let videoCount = callState.model.usersRTC.filter{$0.isVideoTopic}.count
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: videoCount <= 2 ? 1 : 2)
    }
    
    let phoneCellHieght:CGFloat = 150
    
    var body: some View {
        GeometryReader{ reader in
            ZStack{
                if callState.model.isCallStarted{
                    ScrollView(isIpad ? .vertical : .horizontal, showsIndicators: false){
                        if isIpad{
                            LazyVGrid(columns: gridColumns,spacing: 16){
                                ForEach(callState.model.usersRTC.filter{$0.isVideoTopic}, id:\.self){ callUser in
                                    callUserView(callUser)
                                }
                            }
                            .padding([.leading,.trailing], 12)
                        }else{
                            VStack{
                                Spacer()
                                LazyHGrid(rows: [GridItem(.flexible(), spacing: 0)],spacing: 16){
                                    ForEach(callState.model.usersRTC.filter{$0.isVideoTopic}, id:\.self){ callUser in
                                        callUserView(callUser)
                                    }
                                }
                                .frame(height:phoneCellHieght)
                                .offset(y: -148)
                            }
                            .padding([.leading, .trailing],12)
                        }
                    }
                }
                
                VStack(){
                    Spacer()
                    HStack{
                        Spacer()
                        if callState.model.receiveCall != nil && callState.model.isCallStarted == false{
                            receiveCallActions
                        }else{
                            callStartedActions
                        }
                        Spacer()
                    }
                }
                .onAppear{
                    self.statusBarStyle.currentStyle = .lightContent
                }
                .onDisappear{
                    self.statusBarStyle.currentStyle = .default
                }
                if showDetailPanel{
                    getMoreCallControlsView()
                }
                
                recordingDot
            }
        }
        .background(Color(named: "background").ignoresSafeArea())
        .customAnimation(.default)
        .onAppear{
            viewModel.startRequestCallIfNeeded()
        }
        .onChange(of: callState.model.callRecorder, perform: { participant in
            if callState.model.callRecorder != nil{
                showToast = true
            }
        })
        .toast(isShowing: $showToast,
               title: "Recording the call started",
               message: "\(callState.model.callRecorder?.name ?? "")is recording the call",
               image: Image(systemName: "record.circle")
        )
        .onReceive(callState.$model , perform: { _ in
            if callState.model.showCallView == false{
                presentationMode.wrappedValue.dismiss()
            }
        })
    }
    
    @ViewBuilder
    var recordingDot: some View{
        if callState.model.isRecording{
            Image(systemName: "record.circle")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(Color.red)
                .position(x: 32, y: 24)
                .opacity(showRecordingIndicator ? 1 : 0)
                .customAnimation(self.recoringIndicatorAnimation)
                .onAppear{
                    showRecordingIndicator.toggle()
                }
        }
    }
    
    @ViewBuilder
    func getMoreCallControlsView()->some View{
        SheetDialog(showAttachmentDialog: $showDetailPanel) {
            HStack{
                CallControlItem(iconSfSymbolName: "record.circle", subtitle: "Record", color: .red){
                    if callState.model.isRecording{
                        viewModel.stopRecording()
                    }else{
                        viewModel.startRecording()
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
            }.padding()
            
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
    
    @ViewBuilder
    func callUserView(_ userRTC:UserRCT) -> some View{
        if userRTC.isVideoTopic == true, let rendererView = userRTC.renderer as? UIView {
            ZStack{
                if userRTC.videoTrack?.isEnabled == true{
                    RTCVideoReperesentable(renderer: rendererView)
                }else{
                    //only audio
                    Avatar(
                        url: userRTC.callParticipant?.participant?.image,
                        userName: userRTC.callParticipant?.participant?.username?.uppercased(),
                        style: .init(cornerRadius: isIpad ? 64 : 32, size: isIpad ? 128 : 64, textSize: isIpad ? 48 : 24)
                    )
                    .cornerRadius(isIpad ? 64 : 32)
                }
                
                HStack{
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            
                            if let audioUser = callState.model.usersRTC.first(where: {$0.rawTopicName == userRTC.rawTopicName && $0.isAudioTopic}){
                                Image(systemName: audioUser.isMute ? "mic.slash.fill" : "mic.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: isIpad ? 24 : 16, height: isIpad ? 24 : 16)
                                    .foregroundColor(Color.primary)
                            }
                            
                            Image(systemName: userRTC.isVideoOn ? "video" :"video.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIpad ? 24 : 16, height: isIpad ? 24 : 16)
                                .foregroundColor(Color.primary)
                            Text(textLimt(text: userRTC.callParticipant?.participant?.name ?? userRTC.callParticipant?.participant?.username ?? ""))
                                .lineLimit(1)
                                .foregroundColor(Color.primary)
                                .font(isIpad ? .body : .caption2)
                                .opacity(0.8)
                            Spacer()
                        }
                        .fixedSize()
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding()
            }
            .customAnimation(.easeInOut)
            .frame(height: callState.model.usersRTC.filter{$0.isVideoTopic}.count <= 2 ? UIScreen.main.bounds.height / 2 : self.isIpad ? 350 : phoneCellHieght)
            .background(Color(named: "call_item_background").opacity(0.7))
            .border(Color(named: "border_speaking"), width: userRTC.isSpeaking ? 3 : 0)
            .cornerRadius(8)
            .scaleEffect(x: userRTC.isSpeaking ? 1.1 : 1, y: userRTC.isSpeaking ? 1.1 : 1)
        }
    }
    
    @ViewBuilder
    var receiveCallActions:some View{
        VStack{
            
            Text(callState.model.receiveCall?.creator.name != nil ? "Ringing..." : "Calling...")
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.bold)
            
            HStack{
                Spacer()
                if callState.model.receiveCall?.type == .VIDEO_CALL{
                    CallControlItem(iconSfSymbolName: "video.fill", subtitle: "Answer", color: .green){
                        viewModel.answerCall(video: true, audio: true)
                    }
                }
                
                Spacer()
                
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
        }
    }
    
    @ViewBuilder
    var callStartedActions:some View{
        VStack{
            if isIpad{
                Rectangle()
                    .frame(width: 128, height: 5)
                    .foregroundColor(Color.primary)
                    .cornerRadius(5)
                    .offset(y: -36)
            }
            
            HStack{
                Text(callState.model.receiveCall?.creator.name?.uppercased() ?? callState.model.titleOfCalling.uppercased())
                    .foregroundColor(.primary)
                    .font(.title3.bold())
                Spacer()
                Text(callState.model.timerCallString ?? "")
                    .foregroundColor(.primary)
                    .font(.title3.bold())
                
            }
            .fixedSize()
            .padding([.leading,.trailing])
            
            HStack(spacing:16){
                CallControlItem(iconSfSymbolName: "ellipsis", subtitle: "More", color: .gray){
                    withAnimation {
                        showDetailPanel.toggle()
                    }
                }
                
                let isVideoEnabled = callState.model.usersRTC.first(where: {$0.isVideoTopic && $0.direction == .SEND})?.isVideoOn ?? false
                
                ForEach(callState.model.usersRTC.filter{$0.isAudioTopic && $0.direction == .SEND}, id:\.self){ callUser in
                    CallControlItem(iconSfSymbolName: callUser.isMute ? "mic.slash.fill" : "mic.fill", subtitle: "Mute", color: callUser.isMute ? .gray : .green){
                        viewModel.toggleMic()
                    }
                }
                
                CallControlItem(iconSfSymbolName: isVideoEnabled ? "video.fill" : "video.slash.fill", subtitle: "Video", color: isVideoEnabled ? .green : .gray){
                    viewModel.toggleVideo()
                }
                
                CallControlItem(iconSfSymbolName: callState.model.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill", subtitle: "Speaker", color: callState.model.isSpeakerOn ? .green : .gray){
                    viewModel.toggleSpeaker()
                }
                
                CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "End Call", color: .red){
                    viewModel.endCall()
                    withAnimation{
                        callState.model.setShowCallView(false)
                    }
                }
            }
        }
        .padding(isIpad ? [.all] : [.trailing,.leading], isIpad ? 48 : 0)
        .background(controlBackground)
        .cornerRadius(isIpad ? 16 : 0)
    }

    private func textLimt(text:String)->String{
        return String(text.prefix(isIpad ? (text.count < 30 ? text.count : 30) : 15))
    }
    
    @ViewBuilder
    var controlBackground: some View{
        if isIpad{
            Rectangle()
                .fill(Color.clear)
                .background(.ultraThinMaterial)
        }else{
            Color.clear
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
            VStack(spacing:4){
                Circle()
                    .fill(color ?? .blue)
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
                    .fixedSize()
            }
        })
        .buttonStyle(DeepButtonStyle(backgroundColor:Color.clear, shadow:12))
    }
}

struct CallControlsView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        let viewModel = CallControlsViewModel()
        let appState = AppState.shared
        let callState = CallState.shared
        
        CallControlsContent(viewModel:viewModel, showToast: false)
            .preferredColorScheme(.dark)
            .environmentObject(appState)
            .environmentObject(callState)
            .previewDevice("iPhone 13 Pro Max")
            .onAppear(){
                
                let participant = ParticipantRow_Previews.participant
                let receiveCall = CreateCall(type: .VIDEO_CALL, creatorId: 0, creator: participant, threadId: 0, callId: 0, group: false)
                fakeParticipant(count: 20).forEach { callParticipant in
                    callState.addCallParicipant(callParticipant)
                }
                callState.model.setReceiveCall(receiveCall)
                
                let clientDto   = ClientDTO(clientId: "", topicReceive: "", topicSend: "",userId: 0, desc: "", sendKey: "", video: true, mute: false)
                let chatDataDto = ChatDataDTO(sendMetaData: "", screenShare: "", reciveMetaData: "", turnAddress: "", brokerAddressWeb: "", kurentoAddress: "")
                let startedCall = StartCall(certificateFile: "", clientDTO: clientDto, chatDataDto: chatDataDto, callName: nil, callImage: nil)
                
                callState.onCallStarted(NSNotification(name: STARTED_CALL_NAME_OBJECT, object: startedCall))
                callState.model.setIsRecording(isRecording: false)
                callState.model.setStartRecordingDate()
                callState.startRecordingTimer()
                viewModel.setupPreview()
            }
        
    }
    
    static func fakeParticipant(count:Int)->[CallParticipant]{
        var participants:[CallParticipant] = []
        for i in (1...count){
            let participant = ParticipantRow_Previews.participant
            participant.name = "Hamed Hosseini \(i) "
            participants.append(CallParticipant(sendTopic: "TestTopic \(i)", participant:participant))
        }
        return participants
    }
    
}
