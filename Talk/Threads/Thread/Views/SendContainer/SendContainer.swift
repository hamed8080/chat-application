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
                    .fill(Color.App.black.opacity(0.5))
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.13)) {
                            showActionButtons.toggle()
                        }
                    }
            }
            VStack(spacing: 0) {
                Spacer()
                AttachmentFiles()
                    .environmentObject(viewModel.attachmentsViewModel)
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
                            AttachmentButtons(viewModel: viewModel.attachmentsViewModel, showActionButtons: $showActionButtons)
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
                .padding([.bottom, .top], 4)
                .padding([.leading, .trailing], 8)
                .animation(isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: isRecording)
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

struct SendContainer_Previews: PreviewProvider {
    static var previews: some View {
        SendContainer(viewModel: ThreadViewModel(thread: Conversation(id: 0)))
    }
}
