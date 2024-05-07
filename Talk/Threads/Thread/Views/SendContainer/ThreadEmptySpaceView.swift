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
        let navModel = appState.appStateNavigationModel
        let isSameThreadForward = viewModel.threadId == navModel.forwardMessageRequest?.threadId
        let hasForward = navModel.forwardMessages != nil && isSameThreadForward
        let hasReplyPrivately = navModel.replyPrivately != nil
        let replyMessage = viewModel.replyMessage != nil
        let hasEdit = viewModel.sendContainerViewModel.editMessage != nil
        let isShowingAnyContainer = hasForward || audioRecordingVM.isRecording || hasReplyPrivately || replyMessage || hasEdit
        if hasForward { return 116 }
        return isShowingAnyContainer ? 96 : 48
    }

    var body: some View {
        Rectangle()
            .frame(width: 0, height: height)
            .disabled(true)
    }
}
