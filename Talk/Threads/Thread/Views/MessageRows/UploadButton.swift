//
//  UploadButton.swift
//  Talk
//
//  Created by hamed on 2/5/24.
//

import SwiftUI
import TalkViewModels
import ChatModels

struct UploadButton: View {
    @EnvironmentObject var messageRowVM: MessageRowViewModel
    @EnvironmentObject var viewModel: UploadFileViewModel
    @Environment(\.colorScheme) var scheme
    var message: Message { messageRowVM.message }
    var percent: Int64 { viewModel.uploadPercent }
    var stateIcon: String {
        if viewModel.state == .uploading {
            return "xmark"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.up"
        }
    }

    var body: some View {
        if message.uploadFile != nil, viewModel.state != .completed {
            Button {
                manageUpload()
            } label: {
                ZStack {
                    iconView
                    progress
                }
                .frame(width: 46, height: 46)
                .background(scheme == .light ? Color.App.accent : Color.App.white)
                .clipShape(RoundedRectangle(cornerRadius:(46 / 2)))
            }
            .animation(.easeInOut, value: percent)
            .animation(.easeInOut, value: stateIcon)
            .buttonStyle(.borderless)
            .transition(.scale)
        }
    }

    @ViewBuilder private var iconView: some View {
        Image(systemName: stateIcon.replacingOccurrences(of: ".circle", with: ""))
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(Color.black)
            .fontWeight(.medium)
    }

    @ViewBuilder private var progress: some View {
        Circle()
            .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
            .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .foregroundStyle(scheme == .light ? Color.App.textPrimary : Color.App.accent)
            .rotationEffect(Angle(degrees: 270))
            .frame(width: 42, height: 42)
            .environment(\.layoutDirection, .leftToRight)
            .fontWeight(.semibold)
            .rotateAnimtion(pause: viewModel.state == .paused)
    }

    private func manageUpload() {
        if viewModel.state == .paused {
            viewModel.resumeUpload()
        } else if viewModel.state == .uploading {
            viewModel.cancelUpload()
        }
    }
}

struct UploadButton_Previews: PreviewProvider {
    static var previews: some View {
        UploadButton()
    }
}
