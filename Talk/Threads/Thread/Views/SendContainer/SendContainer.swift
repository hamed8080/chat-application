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
                    SelectionView(threadVM: threadVM)
                        .frame(height: selectionHeight)
                        .clipped()
                        .environmentObject(threadVM.selectedMessagesViewModel)
                    MuteChannelViewPlaceholder()
                        .padding(viewModel.canShowMute ? 10 : 0)
                        .frame(height: cahnnelMuteHeight)
                        .clipped()
                    ForwardMessagesViewPlaceholder()
                        .modifier(normalModifier)
                    ReplyPrivatelyMessageViewPlaceholder()
                        .modifier(normalModifier)
                    ReplyMessageViewPlaceholder()
                        .modifier(normalModifier)
                    MentionList()
                        .modifier(normalModifier)
                        .environmentObject(threadVM.mentionListPickerViewModel)
                    EditMessagePlaceholderView()
                        .modifier(normalModifier)
                    AudioOrTextContainer()
                        .modifier(normalModifier)
                }
                .environmentObject(viewModel)
                .opacity(viewModel.disableSend ? 0.3 : 1.0)
                .disabled(viewModel.disableSend)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .animation(.easeInOut, value: viewModel.textMessage.isEmpty)
            }
        }
    }

    private var isInSelection: Bool {
        viewModel.viewModel?.selectedMessagesViewModel.isInSelectMode == true
    }

    private var selectionHeight: CGFloat? {
        isInSelection ? nil : 0
    }

    private var isChannel: Bool {
        viewModel.canShowMute
    }

    private var cahnnelMuteHeight: CGFloat? {
        isChannel ? nil : 0
    }

    private var canShowNormalThreadControls: Bool {
        !(isChannel || isInSelection)
    }

    private var normalThreadHeight: CGFloat? {
        canShowNormalThreadControls ? nil : 0
    }

    private var disableNormalControls: Bool {
        !canShowNormalThreadControls
    }

    private var normalModifier: SendContainerViewModifier {
        SendContainerViewModifier(normalThreadHeight: normalThreadHeight, disableNormalControls: disableNormalControls)
    }
}

struct SendContainerViewModifier: ViewModifier {
    let normalThreadHeight: CGFloat?
    let disableNormalControls: Bool

    func body(content: Content) -> some View {
        content
            .frame(height: normalThreadHeight)
            .disabled(disableNormalControls)
            .clipped()
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
        }
        .animation(.easeInOut, value: viewModel.showRecordingView)
    }
}

struct SendContainer_Previews: PreviewProvider {
    static var previews: some View {
        SendContainer(threadVM: ThreadViewModel(thread: Conversation(id: 0)))
    }
}
