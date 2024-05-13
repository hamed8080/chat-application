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

    var body: some View {
        Rectangle()
            .frame(width: 0, height: height)
            .disabled(true)
    }

    private var height: CGFloat {
        if hasForward { return 116 }
        return isShowingAnyContainer ? 96 : 48
    }

    private var isShowingAnyContainer: Bool {
        hasForward || audioRecordingVM.isRecording || hasReplyPrivately || replyMessage || hasEdit
    }

    private var navModel: AppStateNavigationModel {
        appState.appStateNavigationModel
    }

    /// We have to check if we are increasing the size of next thread not current thread.
    /// If we don't check it, it will lead to first thread get extra empty space
    private var hasReplyPrivately: Bool {
        navModel.replyPrivately != nil && navModel.replyPrivately?.conversation?.id ?? -1 != viewModel.threadId
    }

    private var isSameThreadForward: Bool {
        viewModel.threadId == navModel.forwardMessageRequest?.threadId
    }

    private var hasForward: Bool {
        navModel.forwardMessages != nil && isSameThreadForward
    }

    private var replyMessage: Bool {
        viewModel.replyMessage != nil
    }

    private var hasEdit: Bool {
        viewModel.sendContainerViewModel.editMessage != nil
    }
}
