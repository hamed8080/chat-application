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
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    if viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == true {
//                        SelectionView(threadVM: threadVM)
//                            .environmentObject(threadVM.selectedMessagesViewModel)
                    } else if viewModel.canShowMute {
//                        MuteChannelViewPlaceholder()
//                            .padding(10)
                    } else {
//                        ForwardMessagesViewPlaceholder()
//                            .environmentObject(viewModel)
//                        ReplyPrivatelyMessageViewPlaceholder()
//                            .environmentObject(viewModel)
//                        ReplyMessageViewPlaceholder()
//                            .environmentObject(viewModel)
//                        MentionList()
//                            .environmentObject(threadVM.mentionListPickerViewModel)
//                            .environmentObject(viewModel)
//                        EditMessagePlaceholderView()
//                            .environmentObject(viewModel)
                        AudioOrTextContainer()
                    }
                }
                .opacity(viewModel.disableSend ? 0.3 : 1.0)
                .disabled(viewModel.disableSend)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .animation(.easeInOut, value: viewModel.textMessage.isEmpty)
            }
        }
    }
}

struct AudioOrTextContainer: View {
    @EnvironmentObject var viewModel: SendContainerViewModel
    @EnvironmentObject var audioRecordingVM: AudioRecordingViewModel

    var body: some View {
        ZStack {
//            AudioRecordingView()
//                .padding([.trailing], 12)
//                .animation(audioRecordingVM.isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: audioRecordingVM.isRecording)
//                .scaleEffect(x: viewModel.showRecordingView ? 1.0 : 0.001, y: viewModel.showRecordingView ? 1.0 : 0.001, anchor: .center)
//            MainSendButtons()
//                .environment(\.layoutDirection, .leftToRight)
////                .animation(audioRecordingVM.isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: audioRecordingVM.isRecording)
//                .scaleEffect(x: viewModel.showRecordingView ? 0.001 : 1.0, y: viewModel.showRecordingView ? 0.001 : 1.0, anchor: .center)
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
                    .environmentObject(viewModel.unreadMentionsViewModel)
                CloseRecordingButton()
            }
            .padding(EdgeInsets(top: 0, leading: viewModel.audioRecoderVM.isRecording ? 20 : 8, bottom: 8, trailing: 0))
        }
    }
}

struct SendContainer_Previews: PreviewProvider {
    static var previews: some View {
        SendContainer(threadVM: ThreadViewModel(thread: Conversation(id: 0)))
    }
}
