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
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    @State var showActionButtons: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if showActionButtons {
                Rectangle()
                    .fill(Color.App.black.opacity(0.5))
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.13)) {
                            showActionButtons.toggle()
                        }
                    }
            }
            VStack(spacing: 0) {
                SendContainerOverButtons()
                AttachmentFiles()
                    .environmentObject(viewModel.attachmentsViewModel)
                VStack(spacing: 0) {
                    if isInEditMode {
                        SelectionView(threadVM: viewModel)
                            .environmentObject(viewModel.selectedMessagesViewModel)
                    } else if viewModel.canShowMute {
                        MuteChannelViewPlaceholder()
                            .padding(10)
                    } else {
                        ForwardMessagesViewPlaceholder()
                            .environmentObject(viewModel)
                        ReplyPrivatelyMessageViewPlaceholder()
                            .environmentObject(viewModel)
                        ReplyMessageViewPlaceholder()
                            .environmentObject(viewModel)
                        MentionList(text: $text)
                            .frame(maxHeight: 320)
                            .environmentObject(viewModel)
                        EditMessagePlaceholderView()
                            .environmentObject(viewModel)

                        if showActionButtons {
                            AttachmentButtons(viewModel: viewModel.attachmentsViewModel, showActionButtons: $showActionButtons)
                        }
                        AudioOrTextContainer(text: $text, showActionButtons: $showActionButtons, threadId: viewModel.threadId)
                    }
                }
                .opacity(disableSend ? 0.3 : 1.0)
                .disabled(disableSend)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3), value: text.isEmpty)
                .background(
                    MixMaterialBackground()
                        .cornerRadius(showActionButtons && viewModel.attachmentsViewModel.attachments.count == 0 ? 24 : 0, corners: [.topLeft, .topRight])
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
                .onChange(of: text) { newValue in
                    viewModel.searchForParticipantInMentioning(newValue)
                    if newValue != viewModel.textMessage {
                        viewModel.textMessage = newValue
                    }
                    if !newValue.isEmpty {
                        UserDefaults.standard.setValue(newValue, forKey: "draft-\(viewModel.threadId)")
                    } else {
                        UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
                    }
                }

            }
        }
    }

    private var disableSend: Bool { viewModel.thread.disableSend && isInEditMode == false && !viewModel.canShowMute }
}

struct AudioOrTextContainer: View {
    @Binding var text: String
    @Binding var showActionButtons: Bool
    var threadId: Int
    @EnvironmentObject var audioRecordingVM: AudioRecordingViewModel
    var showRecordingView: Bool { audioRecordingVM.isRecording == true || audioRecordingVM.recordingOutputPath != nil }
    var body: some View {
        ZStack {
            AudioRecordingView()
                .padding([.trailing], 12)
                .animation(audioRecordingVM.isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: audioRecordingVM.isRecording)
                .scaleEffect(x: showRecordingView ? 1.0 : 0.001, y: showRecordingView ? 1.0 : 0.001, anchor: .center)
            MainSendButtons(showActionButtons: $showActionButtons, text: $text)
                .environment(\.layoutDirection, .leftToRight)
                .animation(audioRecordingVM.isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: audioRecordingVM.isRecording)
                .scaleEffect(x: showRecordingView ? 0.001 : 1.0, y: showRecordingView ? 0.001 : 1.0, anchor: .center)
                .onAppear {
                    if let draft = UserDefaults.standard.string(forKey: "draft-\(threadId)"), !draft.isEmpty {
                        text = draft
                    }
                }
        }
        .animation(.easeInOut, value: showRecordingView)
    }
}

struct SendContainerOverButtons: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @EnvironmentObject var audioRecordingVM: AudioRecordingViewModel

    var body: some View {
        if audioRecordingVM.isRecording || viewModel.thread.mentioned == true {
            VStack(alignment: .trailing, spacing: 8) {
                UnreadMentionsButton()
                CloseRecordingButton()
            }
            .padding(EdgeInsets(top: 0, leading: viewModel.audioRecoderVM.isRecording ? 20 : 14, bottom: 8, trailing: 0))
        }
    }
}

struct SendContainer_Previews: PreviewProvider {
    static var previews: some View {
        SendContainer(viewModel: ThreadViewModel(thread: Conversation(id: 0)))
    }
}
