//
//  ThreadEmptySpaceView.swift
//  Talk
//
//  Created by hamed on 12/19/23.
//

import SwiftUI
import TalkViewModels

struct ThreadEmptySpaceView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ThreadViewModel /// It's need to refresh ui when close a forward
    @EnvironmentObject var audioRecordingVM: AudioRecordingViewModel

    var height: CGFloat {
        let isSameThreadForward = viewModel.threadId == appState.appStateNavigationModel.forwardMessageRequest?.threadId
        let hasForward = appState.appStateNavigationModel.forwardMessages != nil && isSameThreadForward
        let hasReplyPrivately = appState.appStateNavigationModel.replyPrivately != nil
        let replyMessage = viewModel.replyMessage != nil
        let hasEdit = viewModel.sendContainerViewModel.editMessage != nil
        let isShowingAnyContainer = hasForward || audioRecordingVM.isRecording || hasReplyPrivately || replyMessage || hasEdit
        return isShowingAnyContainer ? 96 : 48
    }

    var body: some View {
        Rectangle()
            .frame(width: 0, height: height)
    }
}
