//
//  CallControlsContent.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI
import WebRTC

struct CallControlsContent: View {
    @EnvironmentObject
    var viewModel: CallControlsViewModel

    @EnvironmentObject
    var callState: CallState

    @Environment(\.localStatusBarStyle)
    var statusBarStyle: LocalStatusBarStyle

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    var gridColumns: [GridItem] {
        let videoCount = callState.model.usersRTC.filter { $0.isVideoTopic }.count
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: videoCount <= 2 ? 1 : 2)
    }

    var videoUsers: [UserRCT] { callState.model.usersRTC.filter { $0.isVideoTopic } }

    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                self.viewModel.location = value.location
            }
    }

    var body: some View {
        ZStack {
            CenterAciveUserRTCView()
            if callState.model.isCallStarted, isIpad {
                listLargeIpadParticipants
                GeometryReader { reader in
                    CallStartedActionsView()
                        .position(viewModel.location)
                        .gesture(
                            simpleDrag.simultaneously(with: simpleDrag)
                        )
                        .onAppear {
                            viewModel.location = CGPoint(x: reader.size.width / 2, y: reader.size.height - 128)
                        }
                }
            } else if callState.model.isCallStarted {
                VStack {
                    Spacer()
                    listSmallCallParticipants
                    CallStartedActionsView()
                }
            }
            StartCallActionsView()
            RecordingDotView()
        }
        .animation(.easeInOut(duration: 0.5), value: callState.model.usersRTC.count)
        .background(Color(named: "background").ignoresSafeArea())
        .onAppear {
            self.statusBarStyle.currentStyle = .lightContent
            viewModel.startRequestCallIfNeeded()
        }
        .onDisappear {
            self.statusBarStyle.currentStyle = .default
        }
        .onChange(of: callState.model.callRecorder) { _ in
            if callState.model.callRecorder != nil {
                viewModel.showToast = true
            }
        }
        .toast(isShowing: $viewModel.showToast,
               title: "Recording the call started",
               message: "\(callState.model.callRecorder?.name ?? "")is recording the call",
               image: Image(systemName: "record.circle"))
        .onReceive(callState.$model) { _ in
            if callState.model.showCallView == false {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .sheet(isPresented: $viewModel.showDetailPanel) {
            MoreControlsView()
        }
        .sheet(isPresented: $viewModel.showCallParticipants) {
            CallParticipantsContentList()
                .environmentObject(CallParticipantsViewModel(callId: callState.model.startCall?.callId ?? 0))
        }
    }

    @ViewBuilder
    var listLargeIpadParticipants: some View {
        if videoUsers.count <= 2 {
            HStack(spacing: 16) {
                ForEach(videoUsers) { videoUser in
                    UserRTCView(userRTC: videoUser)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .padding([.leading, .trailing], 12)
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(videoUsers) { videoUser in
                        UserRTCView(userRTC: videoUser)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                }
                .padding([.leading, .trailing], 12)
            }
        }
    }

    @ViewBuilder
    var listSmallCallParticipants: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: [GridItem(.flexible(), spacing: 0)], spacing: 0) {
                ForEach(videoUsers) { videoUser in
                    UserRTCView(userRTC: videoUser)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .onTapGesture {
                            viewModel.activeLargeCall = videoUser
                        }
                }
                .padding([.all], isIpad ? 8 : 6)
            }
        }
        .frame(height: callState.defaultCellHieght + 25) // +25 for when a user start talking showing frame
    }
}

struct CenterAciveUserRTCView: View {
    @EnvironmentObject
    var viewModel: CallControlsViewModel

    var userRTC: UserRCT? {
        viewModel.activeLargeCall
    }

    var activeLargeRenderer = RTCMTLVideoView(frame: .zero)

    var body: some View {
        if var userRTC = userRTC {
            if userRTC.isVideoTrackEnable == true {
                RTCVideoReperesentable(renderer: activeLargeRenderer)
                    .ignoresSafeArea()
                    .onAppear {
                        userRTC.addVideoRenderer(activeLargeRenderer)
                    }

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            userRTC.removeVideoRenderer(activeLargeRenderer)
                            self.viewModel.activeLargeCall = nil
                        } label: {
                            Image(systemName: "xmark.circle")
                                .resizable()
                                .foregroundColor(.primary)
                        }
                        .frame(width: 36, height: 36)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                // only audio
                Avatar(
                    url: userRTC.callParticipant?.participant?.image,
                    userName: userRTC.callParticipant?.participant?.username?.uppercased(),
                    style: .init(cornerRadius: isIpad ? 64 : 32, size: isIpad ? 128 : 64, textSize: isIpad ? 48 : 24)
                )
                .cornerRadius(isIpad ? 64 : 32)
            }
        } else {
            EmptyView()
        }
    }
}

struct RecordingDotView: View {
    @EnvironmentObject
    var callState: CallState

    @State
    var showRecordingIndicator: Bool = false

    var body: some View {
        if callState.model.isRecording {
            Image(systemName: "record.circle")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(Color.red)
                .position(x: 32, y: 24)
                .opacity(showRecordingIndicator ? 1 : 0)
                .animation(.easeInOut, value: showRecordingIndicator)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: showRecordingIndicator ? 0.7 : 1, repeats: true) { _ in
                        showRecordingIndicator.toggle()
                    }
                }
        } else {
            EmptyView()
        }
    }
}

/// When receive or start call to someone you will see this screen and it will show only if call is not started.
struct StartCallActionsView: View {
    @EnvironmentObject
    var callState: CallState

    @EnvironmentObject
    var viewModel: CallControlsViewModel

    var body: some View {
        if callState.model.isCallStarted == false {
            VStack {
                Spacer()
                Text(callState.model.receiveCall?.creator.name != nil ? "Ringing..." : "Calling...")
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    Spacer()
                    if callState.model.receiveCall?.type == .videoCall {
                        CallControlItem(iconSfSymbolName: "video.fill", subtitle: "Answer", color: .green) {
                            viewModel.answerCall(video: true, audio: true)
                        }
                    }

                    Spacer()

                    CallControlItem(iconSfSymbolName: "phone.fill", subtitle: "Answer", color: .green) {
                        viewModel.answerCall(video: false, audio: true)
                    }

                    Spacer()

                    CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "Reject Call", color: .red) {
                        viewModel.cancelCall()
                        withAnimation {
                            callState.model.setShowCallView(false)
                        }
                    }

                    Spacer()
                }
            }
        }
    }
}

struct MoreControlsView: View {
    @EnvironmentObject
    var callState: CallState

    @EnvironmentObject
    var viewModel: CallControlsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                CallControlItem(iconSfSymbolName: "record.circle", subtitle: "Record", color: .red, vertical: true) {
                    if callState.model.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }

                if callState.model.isRecording {
                    Spacer()
                    Text(callState.model.recordingTimerString ?? "")
                        .fontWeight(.medium)
                        .padding([.leading, .trailing], 16)
                        .padding([.top, .bottom], 8)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.thinMaterial)
                        )
                }
            }

            CallControlItem(iconSfSymbolName: "person.fill.badge.plus", subtitle: "prticipants", color: .gray, vertical: true) {
                withAnimation {
                    viewModel.showDetailPanel.toggle()
                    viewModel.showCallParticipants.toggle()
                }
            }
            .layoutPriority(2)

            CallControlItem(iconSfSymbolName: "questionmark.app.fill", subtitle: "Update Participants Status", color: .blue, vertical: true) {
                callState.callInquiry()
            }

            Spacer()
        }
        .padding()
    }
}

struct CallStartedActionsView: View {
    @EnvironmentObject
    var callState: CallState

    @EnvironmentObject
    var viewModel: CallControlsViewModel

    var body: some View {
        VStack {
            if isIpad {
                Rectangle()
                    .frame(width: 128, height: 5)
                    .foregroundColor(Color.primary)
                    .cornerRadius(5)
                    .offset(y: -36)
            }

            if viewModel.socketStatus != .connected {
                Text(viewModel.socketStatus.stringValue.appending(" ...").uppercased())
                    .font(.subheadline.weight(.medium))
                    .padding(.bottom, 2)
            }

            HStack {
                Text(callState.model.receiveCall?.creator.name?.uppercased() ?? callState.model.titleOfCalling.uppercased())
                    .foregroundColor(.primary)
                    .font(.title3.bold())
                Spacer()
                Text(callState.model.timerCallString ?? "")
                    .foregroundColor(.primary)
                    .font(.title3.bold())
            }
            .fixedSize()
            .padding([.leading, .trailing])

            HStack(spacing: 16) {
                CallControlItem(iconSfSymbolName: "ellipsis", subtitle: "More", color: .gray) {
                    withAnimation {
                        viewModel.showDetailPanel.toggle()
                    }
                }

                let isVideoEnabled = callState.model.usersRTC.first(where: { $0.isVideoTopic && $0.direction == .send })?.isVideoOn ?? false
                if let audioCallUser = callState.model.usersRTC.filter { $0.isAudioTopic && $0.direction == .send }.first, let audioCallUser = audioCallUser {
                    CallControlItem(iconSfSymbolName: audioCallUser.isMute ? "mic.slash.fill" : "mic.fill", subtitle: "Mute", color: audioCallUser.isMute ? .gray : .green) {
                        viewModel.toggleMic()
                    }
                }

                CallControlItem(iconSfSymbolName: isVideoEnabled ? "video.fill" : "video.slash.fill", subtitle: "Video", color: isVideoEnabled ? .green : .gray) {
                    viewModel.toggleVideo()
                }

                CallControlItem(iconSfSymbolName: callState.model.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill", subtitle: "Speaker", color: callState.model.isSpeakerOn ? .green : .gray) {
                    viewModel.toggleSpeaker()
                }

                CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "End Call", color: .red) {
                    viewModel.endCall()
                    withAnimation {
                        callState.model.setShowCallView(false)
                    }
                }
            }
        }
        .animation(.easeInOut, value: viewModel.socketStatus)
        .padding(isIpad ? [.all] : [.trailing, .leading], isIpad ? 48 : 16)
        .background(controlBackground)
        .cornerRadius(isIpad ? 16 : 0)
    }

    @ViewBuilder
    var controlBackground: some View {
        if isIpad {
            Rectangle()
                .fill(Color.clear)
                .background(.ultraThinMaterial)
        } else {
            Color.clear
        }
    }
}

struct CallControlItem: View {
    var iconSfSymbolName: String
    var subtitle: String
    var color: Color? = nil
    var vertical: Bool = false
    var action: (()->Void)?

    @State var isActive = false

    var body: some View {
        Button(action: {
            isActive.toggle()
            action?()
        }, label: {
            if vertical {
                HStack {
                    content
                }
            } else {
                VStack {
                    content
                }
            }
        })
        .buttonStyle(DeepButtonStyle(backgroundColor: Color.clear, shadow: 12))
    }

    @ViewBuilder
    var content: some View {
        Circle()
            .fill(color ?? .blue)
            .overlay(
                Image(systemName: iconSfSymbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .padding(2)
            )
            .frame(width: 52, height: 52)
        Text(subtitle)
            .fontWeight(.bold)
            .font(.system(size: 10))
            .fixedSize()
    }
}

struct UserRTCView: View {
    let userRTC: UserRCT

    @EnvironmentObject
    var callState: CallState

    var audioUser: UserRCT? {
        callState.model.usersRTC.first(where: { $0.rawTopicName == userRTC.rawTopicName && $0.isAudioTopic })
    }

    var body: some View {
        if userRTC.isVideoTopic == true, let rendererView = userRTC.renderer as? UIView {
            ZStack {
                if userRTC.isVideoTrackEnable == true {
                    RTCVideoReperesentable(renderer: rendererView)
                } else {
                    // only audio
                    Avatar(
                        url: userRTC.callParticipant?.participant?.image,
                        userName: userRTC.callParticipant?.participant?.username?.uppercased(),
                        style: .init(cornerRadius: isIpad ? 64 : 32, size: isIpad ? 128 : 64, textSize: isIpad ? 48 : 24)
                    )
                    .cornerRadius(isIpad ? 64 : 32)
                }

                HStack {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()

                            if let audioUser = audioUser {
                                Image(systemName: audioUser.isMute ? "mic.slash.fill" : "mic.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: isIpad ? 24 : 16, height: isIpad ? 24 : 16)
                                    .foregroundColor(Color.primary)
                            }

                            Image(systemName: userRTC.isVideoOn ? "video" : "video.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIpad ? 24 : 16, height: isIpad ? 24 : 16)
                                .foregroundColor(Color.primary)
                            Text(userRTC.callParticipant?.participant?.name ?? userRTC.callParticipant?.participant?.username ?? "")
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
            .frame(height: callState.defaultCellHieght)
            .background(Color(named: "call_item_background").opacity(0.7))
            .border(Color(named: "border_speaking"), width: userRTC.isSpeaking ? 3 : 0)
            .cornerRadius(8)
            .scaleEffect(x: userRTC.isSpeaking ? 1.05 : 1, y: userRTC.isSpeaking ? 1.05 : 1)
            .animation(.easeInOut, value: userRTC.isSpeaking)
        }
    }
}

struct CallControlsView_Previews: PreviewProvider {
    static let viewModel = CallControlsViewModel()

    @ObservedObject
    static var callState = CallState.shared

    static var previews: some View {
        Group {
            CallControlsContent()
                .previewDisplayName("CallControlsContent")
            StartCallActionsView()
                .previewDisplayName("StartCallActionsView")
            CallControlItem(iconSfSymbolName: "trash", subtitle: "Delete")
                .previewDisplayName("CallControlItem")
            CallStartedActionsView()
                .previewDisplayName("CallStartedActionsView")
            MoreControlsView()
                .previewDisplayName("MoreControlsView")
        }
        .environmentObject(AppState.shared)
        .environmentObject(callState)
        .environmentObject(viewModel)
        .onAppear {
            callAllNeededMethodsForPreview()
        }
    }

    static func callAllNeededMethodsForPreview() {
        fakeParticipant(count: 5).forEach { callParticipant in
            callState.addCallParicipant(callParticipant)
        }
        let participant = MockData.participant
        let receiveCall = CreateCall(type: .videoCall, creatorId: 0, creator: participant, threadId: 0, callId: 0, group: false)
        let clientDto = ClientDTO(clientId: "", topicReceive: "", topicSend: "", userId: 0, desc: "", sendKey: "", video: true, mute: false)
        let chatDataDto = ChatDataDTO(sendMetaData: "", screenShare: "", reciveMetaData: "", turnAddress: "", brokerAddressWeb: "", kurentoAddress: "")
        let startedCall = StartCall(certificateFile: "", clientDTO: clientDto, chatDataDto: chatDataDto, callName: nil, callImage: nil)
        callState.model.setReceiveCall(receiveCall)
        callState.onCallStarted(startedCall)
        callState.model.setIsRecording(isRecording: true)
        callState.model.setStartRecordingDate()
        callState.startRecordingTimer()
    }

    static func fakeParticipant(count: Int)->[CallParticipant] {
        var participants: [CallParticipant] = []
        for i in 1 ... count {
            let participant = MockData.participant
            participant.name = "Hamed Hosseini \(i) "
            participants.append(CallParticipant(sendTopic: "TestTopic \(i)", participant: participant))
        }
        return participants
    }
}
