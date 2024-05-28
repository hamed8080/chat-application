//
//  MessageRowAudioView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels
import ChatModels

struct MessageRowAudioView: View {
    /// We have to use EnvironmentObject due to we need to update ui after the audio has been uploaded so downloadVM now is not a nil value.
    @EnvironmentObject var viewModel: MessageRowViewModel
    @EnvironmentObject var audioVM: AVAudioPlayerViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !viewModel.calMessage.isMe {
                button
            }

            VStack(alignment: .leading, spacing: 4) {
                fileNameView
                audioProgress
                HStack {
                    fileTypeView
                    fileSizeView
                }
            }

            if viewModel.calMessage.isMe {
                button
            }
        }
        .padding(4)
        .padding(.top, viewModel.calMessage.sizes.paddings.fileViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
    }

    @ViewBuilder private var audioProgress: some View {
        VStack(alignment: .leading, spacing: 1) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(Color.App.textPrimary)
                .frame(maxWidth: 172)
            let timerString = viewModel.audioTimerString
            Text(timerString)
                .foregroundColor(Color.App.textPrimary)
                .frame(minHeight: 10)
        }
    }

    @ViewBuilder private var fileNameView: some View {
        if let fileName = viewModel.calMessage.fileName {
            Text(fileName)
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldCaption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder private var fileTypeView: some View {
        if let extName = viewModel.calMessage.extName {
            Text(extName)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }

    @ViewBuilder private var fileSizeView: some View {
        if let fileZize = viewModel.calMessage.computedFileSize {
            Text(fileZize)
                .multilineTextAlignment(.leading)
                .font(.iransansCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }

    @ViewBuilder private var button: some View {
        ZStack {
            if showDownloadButton {
                DownloadButton() {
                    viewModel.onTap()
                }
            } else if isUploading {
                UploadButton()
            } else {
                PlayingButton()
            }
        }
        .frame(width: 46, height: 46) /// prevent the button lead to huge resize afetr upload completed.
        .animation(.easeInOut, value: viewModel.fileState.isUploading)
    }
}

private extension MessageRowAudioView {
    var isUploading: Bool {
        viewModel.fileState.isUploading && !viewModel.fileState.isUploadCompleted
    }

    var isCompleted: Bool {
        viewModel.fileState.state == .completed && viewModel.fileState.state != .undefined
    }

    var showDownloadButton: Bool {
        !isUploading && !isCompleted
    }

    var playable: Bool{
        !isUploading && isCompleted
    }

    var isSameFile: Bool {
        viewModel.fileState.url != nil && audioVM.fileURL?.absoluteString == viewModel.fileState.url?.absoluteString
    }

    var progress: CGFloat {
        isSameFile ? min(audioVM.currentTime / audioVM.duration, 1.0) : 0
    }
}

fileprivate struct PlayingButton: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    @EnvironmentObject var audioVM: AVAudioPlayerViewModel

    var body: some View {
        if viewModel.fileState.state == .completed {
            Button {
                viewModel.onTap()
            } label: {
                ZStack {
                    imageView
                }
                .frame(width: 46, height: 46)
                .background(Color.App.accent)
                .clipShape(RoundedRectangle(cornerRadius:(23)))
            }
            .buttonStyle(.borderless)
        }
    }

    private var imageView: some View {
        Image(systemName: playingIcon)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(Color.App.white)
            .fontWeight(.medium)
    }

    private var playingIcon: String {
        if audioVM.isPlaying && isSameFile {
            return "pause.fill"
        } else {
            return "play.fill"
        }
    }

    private var isSameFile: Bool {
        viewModel.fileState.url != nil && audioVM.fileURL?.absoluteString == viewModel.fileState.url?.absoluteString
    }
}

struct MessageRowAudioDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowAudioView()
            .environmentObject(MessageRowViewModel(message: Message(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
