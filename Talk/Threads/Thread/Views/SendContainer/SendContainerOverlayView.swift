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
            if viewModel.showActionButtons {
                Rectangle()
                    .fill(Color.App.bgSecondary.opacity(0.4))
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.13)) {
                            viewModel.showActionButtons.toggle()
                        }
                    }
            }

            VStack(spacing: 0) {
                if viewModel.showActionButtons {
                    AttachmentButtons(viewModel: threadVM.attachmentsViewModel)
                }
                AttachmentFiles()
                    .environmentObject(threadVM.attachmentsViewModel)
                    .padding(.top, threadVM.attachmentsViewModel.attachments.count > 0 ? 8 : 0)
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
