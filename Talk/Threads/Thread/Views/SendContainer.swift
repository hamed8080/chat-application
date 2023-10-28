//
//  SendContainer.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import AdditiveUI
import ChatModels
import Combine
import SwiftUI
import TalkUI
import TalkViewModels
import Chat
import TalkExtensions

struct SendContainer: View {
    @State private var isInEditMode: Bool = false
    let viewModel: ThreadViewModel
    @State private var text: String = ""
    @State private var isRecording = false
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    private var threadId: Int? { viewModel.thread.id }
    @State var showActionButtons: Bool = false

    var body: some View {
        ZStack {
            if showActionButtons {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.13)) {
                            showActionButtons.toggle()
                        }
                    }
            }
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    if isInEditMode {
                        SelectionView(viewModel: viewModel)
                    } else if viewModel.canShowMute {
                        MuteChannelViewPlaceholder()
                            .padding(10)
                    } else {
                        ReplyMessageViewPlaceholder()
                            .environmentObject(viewModel)
                        MentionList(text: $text)
                            .frame(maxHeight: 320)
                            .environmentObject(viewModel)
                        EditMessagePlaceholderView()
                            .environmentObject(viewModel)

                        if showActionButtons {
                            AttachmentButtons(viewModel: viewModel.sheetViewModel, showActionButtons: $showActionButtons)
                        }

                        if let recordingVM = viewModel.audioRecoderVM {
                            AudioRecordingView(isRecording: $isRecording)
                                .environmentObject(recordingVM)
                                .padding([.trailing], 12)
                        }
                        MainSendButtons(showActionButtons: $showActionButtons, isRecording: $isRecording, text: $text)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
                .opacity(disableSend ? 0.3 : 1.0)
                .disabled(disableSend)
                .padding(.bottom, 4)
                .padding([.leading, .trailing], 8)
                .padding(.top, 4)
                .animation(isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: isRecording)
                .background(
                    MixMaterialBackground()
                        .cornerRadius(showActionButtons ? 24 : 0, corners: [.topLeft, .topRight])
                        .ignoresSafeArea()
                )
                .onReceive(viewModel.$editMessage) { editMessage in
                    text = editMessage?.message ?? ""
                }
                .onReceive(viewModel.$isInEditMode) { newValue in
                    if newValue != isInEditMode {
                        isInEditMode = newValue
                    }
                }
                .onReceive(Just(viewModel.audioRecoderVM?.isRecording)) { newValue in
                    isRecording = newValue ?? false
                }
                .onChange(of: text) { newValue in
                    viewModel.searchForParticipantInMentioning(newValue)
                    viewModel.textMessage = newValue
                    if !newValue.isEmpty {
                        UserDefaults.standard.setValue(newValue, forKey: "draft-\(viewModel.threadId)")
                    } else {
                        UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
                    }
                }
                .onAppear {
                    if let threadId = threadId, let draft = UserDefaults.standard.string(forKey: "draft-\(threadId)"), !draft.isEmpty {
                        text = draft
                    }
                }
            }
        }
    }

    private var disableSend: Bool { viewModel.thread.disableSend && isInEditMode == false && !viewModel.canShowMute }
}

struct MainSendButtons: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var showActionButtons: Bool
    @Binding var isRecording: Bool
    @Binding var text: String

    var body: some View {
        HStack(spacing: 0) {
            if isRecording == false {
                Button {
                    withAnimation(animation(appear: !showActionButtons)) {
                        showActionButtons.toggle()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, showActionButtons ? Color.hint.opacity(0.5) : Color.main )
                        .frame(width: 26, height: 26)
                }
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .buttonStyle(.borderless)
                .fontWeight(.light)
            }

            MultilineTextField(text.isEmpty == true ? "Thread.SendContainer.typeMessageHere" : "",
                               text: $text,
                               textColor: UIColor(named: "message_text"),
                               backgroundColor: Color.bgChatBox,
                               mention: true)
            .cornerRadius(24)
            .environment(\.layoutDirection, Locale.current.identifier.contains("fa") ? .rightToLeft : .leftToRight)
            .onChange(of: viewModel.textMessage ?? "") { newValue in
                viewModel.sendStartTyping(newValue)
            }

            if isRecording == false {
                Button {
                    viewModel.setupRecording()
                    isRecording = true
                } label: {
                    Image(systemName: "mic.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 24)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.hint)
                }
                .frame(width: 48, height: 48)
                .buttonStyle(.borderless)
                .fontWeight(.light)
                .keyboardShortcut(.init("r"), modifiers: [.command])
            }

            Button {
                viewModel.setupRecording()
                isRecording = true
            } label: {
                Image(systemName: "camera")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.hint)
            }
            .frame(width: 48, height: 48)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            .keyboardShortcut(.init("r"), modifiers: [.command])
            .disabled(true)
            .opacity(0.2)

            Button {
                if isRecording {
                    viewModel.audioRecoderVM?.stopAndSend()
                    isRecording = false
                } else if !text.isEmpty {
                    viewModel.sendTextMessage(text)
                }
                text = ""
                viewModel.sheetType = nil
                viewModel.animateObjectWillChange()
                UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color.main)
            }
            .frame(width: 48, height: 48)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            .keyboardShortcut(.return, modifiers: [.command])
        }
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }
}

struct SelectionView: View {
    let viewModel: ThreadViewModel
    @State private var selectedCount: Int = 0

    var body: some View {
        HStack {

            Button {
                viewModel.isInEditMode = false
                viewModel.clearSelection()
                viewModel.animateObjectWillChange()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color.main)
                    .frame(width: 26, height: 26)
            }
            .frame(width: 48, height: 48)
            .cornerRadius(24)
            .buttonStyle(.borderless)
            .fontWeight(.light)

            HStack(spacing: 2) {
                Text("\(selectedCount)")
                    .fontWeight(.bold)
                Text("General.selected")
                if viewModel.forwardMessage != nil {
                    Text("Thread.SendContainer.toForward")
                }
            }
            .font(.iransansBody)
            .offset(x: 8)
            Spacer()

            /// Disable showing the delete button when forwarding in a conversation where we are not the admin and we just want to forward messages, so the delete button should be hidden.
            if !viewModel.thread.disableSend {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.redSoft)
                    .padding()
                    .onTapGesture {
                        viewModel.deleteDialaog.toggle()
                    }
            }

            Image(systemName: "arrowshape.turn.up.right.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.blue)
                .padding()
                .onTapGesture {
                    viewModel.sheetType = .threadPicker
                    viewModel.animateObjectWillChange()
                }
        }
        .onReceive(viewModel.objectWillChange) { _ in
            withAnimation {
                selectedCount = viewModel.selectedMessages.count
            }
        }
    }
}

struct ReplyMessageViewPlaceholder: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if let replyMessage = viewModel.replyMessage {
            HStack {
                Button {
                    viewModel.replyMessage = nil
                    viewModel.clearSelection()
                    viewModel.animateObjectWillChange()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.main)
                        .frame(width: 26, height: 26)
                }
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .buttonStyle(.borderless)
                .fontWeight(.light)

                Text(replyMessage.message ?? replyMessage.fileMetaData?.name ?? "")
                    .font(.iransansBody)
                    .offset(x: 8)
                    .onTapGesture {
                        // TODO: Go to reply message location
                    }
                Spacer()
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 16))
                    .scaledToFit()
                    .foregroundColor(Color.gray)
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
        }
    }
}

struct MuteChannelViewPlaceholder: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @State var mute: Bool = false

    var body: some View {
        if viewModel.canShowMute {
            HStack(spacing: 0) {
                Spacer()
                Image(systemName: mute ? "speaker.fill" : "speaker.slash.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color.blue)
                Text(mute ? "Thread.unmute" : "Thread.mute")
                    .font(.iransansBody)
                    .offset(x: 8)
                Spacer()
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .onTapGesture {
                viewModel.threadsViewModel?.toggleMute(viewModel.thread)
            }
            .onReceive(NotificationCenter.default.publisher(for: .thread)) { newValue in
                if let event = newValue.object as? ThreadEventTypes {
                    if case let .mute(response) = event, response.subjectId == viewModel.threadId {
                        mute = true
                    }

                    if case let .unmute(response) = event, response.subjectId == viewModel.threadId {
                        mute = false
                    }
                }
            }
            .onAppear {
                mute = viewModel.thread.mute ?? false
            }
            .animation(.easeInOut, value: mute)
        }
    }
}

struct EditMessagePlaceholderView: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if let editMessage = viewModel.editMessage {
            HStack {
                Button {
                    viewModel.isInEditMode = false
                    viewModel.editMessage = nil
                    viewModel.textMessage = nil
                    viewModel.animateObjectWillChange()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.main)
                        .frame(width: 26, height: 26)
                }
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .buttonStyle(.borderless)
                .fontWeight(.light)

                Text("\(editMessage.message ?? "")")
                    .font(.iransansBody)
                    .offset(x: 8)
                Spacer()
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .padding(.bottom)
        }
    }
}

struct SendContainer_Previews: PreviewProvider {
    static var previews: some View {
        SendContainer(viewModel: ThreadViewModel(thread: Conversation(id: 0)))
    }
}

struct GradientImageButton: View {
    var image: String
    var title: String
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(String(localized: .init(title)))
                .frame(width: 0, height: 0)
                .hidden()
                .allowsHitTesting(false)
                .disabled(true)
            LinearGradient(gradient: Gradient(colors: [.blue, .teal]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask {
                    Image(systemName: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .frame(maxWidth: 24, maxHeight: 24)
        }
    }
}
