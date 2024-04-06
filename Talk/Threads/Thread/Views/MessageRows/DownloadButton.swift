//
//  DownloadButton.swift
//  Talk
//
//  Created by hamed on 2/5/24.
//

import SwiftUI
import TalkViewModels
import TalkModels
import ChatModels

struct DownloadButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    var messageRowVM: MessageRowViewModel
    @EnvironmentObject var audioVM: AVAudioPlayerViewModel
    private var isSameFile: Bool { viewModel.fileURL != nil && audioVM.fileURL?.absoluteString == viewModel.fileURL?.absoluteString }
    @Environment(\.colorScheme) var scheme
    private var message: Message? { viewModel.message }
    private var percent: Int64 { viewModel.downloadPercent }
    let action: () -> Void
    private var stateIcon: String {
        if message?.isAudio == true, viewModel.state == .completed {
            if audioVM.isPlaying {
                return "pause.fill"
            } else {
                return "play.fill"
            }
        } else if let iconName = message?.iconName, viewModel.state == .completed {
            return iconName
        } else if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                iconView
                progress
            }
            .frame(width: 46, height: 46)
            .background(scheme == .light ? Color.App.accent : Color.App.white)
            .clipShape(RoundedRectangle(cornerRadius:(46 / 2)))
            .transition(.scale)
        }
        .buttonStyle(.borderless)
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
        if viewModel.state == .downloading {
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
    }
}

struct DownloadButton_Previews: PreviewProvider {
    static var previews: some View {
        DownloadButton(messageRowVM: .init(message: .init(), viewModel: .init(thread: .init()))) {

        }
    }
}
