//
//  SendContainerOverlayView.swift
//  Talk
//
//  Created by hamed on 12/19/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct SendContainerOverlayView: View {
    @EnvironmentObject var viewModel: SendContainerViewModel
    @EnvironmentObject var threadVM: ThreadViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            dimBackground
            VStack(spacing: 0) {
                HistoryEssentialButtonsOverSendContainer(viewModel: threadVM)
                VStack(spacing: 0) {
                    AttachmentButtons(viewModel: threadVM.attachmentsViewModel)
                        .frame(height: viewModel.showActionButtons ? nil : 0)
                        .contentShape(Rectangle())
                        .clipped()
                        .disabled(!viewModel.showActionButtons)
                    AttachmentFiles()
                        .environmentObject(threadVM.attachmentsViewModel)
                        .padding(.top, viewModel.showActionButtons ? 8 : 0)
                    SendContainer(threadVM: threadVM)
                }
                .background(
                    MixMaterialBackground()
                        .cornerRadius(viewModel.showActionButtons && threadVM.attachmentsViewModel.attachments.count == 0 ? 24 : 0, corners: [.topLeft, .topRight])
                        .ignoresSafeArea()
                        .background(
                            GeometryReader { reader in
                                Color.clear.ignoresSafeArea()
                                    .onAppear {
                                        threadVM.sendContainerViewModel.height = reader.size.height + 24
                                    }
                            }
                        )
                )
            }
        }
    }

    private var dimBackground: some View {
        Rectangle()
            .fill(Color.App.bgSecondary.opacity(0.4))
            .frame(height: viewModel.showActionButtons ? nil : 0)
            .clipped()
            .animation(.none, value: viewModel.showActionButtons)
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.13)) {
                    viewModel.showActionButtons.toggle()
                }
            }
    }
}

struct HistoryEssentialButtonsOverSendContainer: View {
    let viewModel: ThreadViewModel

    var body: some View {
        VStack(spacing: 16) {
            UnreadMentionsButton()
                .environmentObject(viewModel.unreadMentionsViewModel)
            MoveToBottomButton()
            CloseRecordingButton()
        }
    }
}
