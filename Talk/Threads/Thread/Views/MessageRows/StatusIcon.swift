//
//  StatusIcon.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Foundation
import SwiftUI
import TalkViewModels
import ChatModels

public struct StatusIcon: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    var message: Message { viewModel.message }
    @State private var rotateDegree: CGFloat = 0.0

    public var body: some View {
        let footerStatus = message.footerStatus(isUploading: viewModel.fileState.isUploading)
        Image(uiImage: footerStatus.image)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: canShowStatus ? 16 : 0, height: canShowStatus ? 16 : 0)
            .foregroundColor(footerStatus.fgColor)
            .rotationEffect(.degrees(rotateDegree), anchor: .center)
            .padding(.trailing, 2)
            .id(viewModel.fileState.isUploading)
            .onAppear {
                startSendingAnimation()
            }
            .onChange(of: viewModel.message.id) { newValue in
                if newValue != nil && newValue ?? 0 > 0 {
                    withAnimation {
                        rotateDegree = 0
                    }
                }
            }
    }

    private var canShowStatus: Bool {
        viewModel.calMessage.isMe && isSelfThreadDelivered
    }

    private var isSelfThreadDelivered: Bool {
        if !isSelfThread { return true }
        return message.id != nil
    }

    private var isSelfThread: Bool {
        viewModel.threadVM?.thread.type == .selfThread
    }

    private func startSendingAnimation() {
        if viewModel.fileState.isUploading {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotateDegree += 360
            }
        } else {
            rotateDegree = 0
        }
    }
}
