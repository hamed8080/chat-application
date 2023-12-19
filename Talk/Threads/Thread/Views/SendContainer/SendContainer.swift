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
    @EnvironmentObject var viewModel: SendContainerViewModel
    let threadVM: ThreadViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            if viewModel.showActionButtons {
                Rectangle()
                    .fill(Color.App.black.opacity(0.5))
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.13)) {
                            viewModel.showActionButtons.toggle()
                        }
                    }
            }
            VStack(spacing: 0) {
                SendContainerOverButtons()
                AttachmentFiles()
                    .environmentObject(threadVM.attachmentsViewModel)
                VStack(spacing: 0) {
                    if viewModel.isInEditMode {
                        SelectionView(threadVM: threadVM)
                            .environmentObject(threadVM.selectedMessagesViewModel)
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
                        MentionList()
                            .environmentObject(threadVM.mentionListPickerViewModel)
                            .environmentObject(viewModel)
                        EditMessagePlaceholderView()
                            .environmentObject(viewModel)
                        if viewModel.showActionButtons {
                            AttachmentButtons(viewModel: threadVM.attachmentsViewModel)
                        }
                        AudioOrTextContainer()
                    }
                }
                .opacity(viewModel.disableSend ? 0.3 : 1.0)
                .disabled(viewModel.disableSend)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3), value: viewModel.textMessage.isEmpty)
                .background(
                    MixMaterialBackground()
                        .cornerRadius(viewModel.showActionButtons && threadVM.attachmentsViewModel.attachments.count == 0 ? 24 : 0, corners: [.topLeft, .topRight])
                        .ignoresSafeArea()
                )
                .onReceive(viewModel.$editMessage) { editMessage in
                    viewModel.textMessage = editMessage?.message ?? ""
                }
                .onReceive(threadVM.$isInEditMode) { newValue in
                    if newValue != viewModel.isInEditMode {
                        withAnimation {
                            viewModel.isInEditMode = newValue
                        }
                    }
                }
                .onReceive(viewModel.$textMessage) { newValue in
                    threadVM.mentionListPickerViewModel.text = newValue
                    if !newValue.isEmpty {
                        UserDefaults.standard.setValue(newValue, forKey: "draft-\(viewModel.threadId)")
                    } else {
                        UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
                    }
                }
            }
        }
    }
}

struct AudioOrTextContainer: View {
    @EnvironmentObject var viewModel: SendContainerViewModel
    @EnvironmentObject var audioRecordingVM: AudioRecordingViewModel

    var body: some View {
        ZStack {
            AudioRecordingView()
                .padding([.trailing], 12)
                .animation(audioRecordingVM.isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: audioRecordingVM.isRecording)
                .scaleEffect(x: viewModel.showRecordingView ? 1.0 : 0.001, y: viewModel.showRecordingView ? 1.0 : 0.001, anchor: .center)
            MainSendButtons()
                .environment(\.layoutDirection, .leftToRight)
                .animation(audioRecordingVM.isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: audioRecordingVM.isRecording)
                .scaleEffect(x: viewModel.showRecordingView ? 0.001 : 1.0, y: viewModel.showRecordingView ? 0.001 : 1.0, anchor: .center)
                .onAppear {
                    if let draft = UserDefaults.standard.string(forKey: "draft-\(viewModel.threadId)"), !draft.isEmpty {
                        viewModel.textMessage = draft
                    }
                }
        }
        .animation(.easeInOut, value: viewModel.showRecordingView)
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
        SendContainer(threadVM: ThreadViewModel(thread: Conversation(id: 0)))
    }
}
