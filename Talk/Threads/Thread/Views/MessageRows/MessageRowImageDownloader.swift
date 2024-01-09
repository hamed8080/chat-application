//
//  MessageRowImageDownloader.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import Chat

struct MessageRowImageDownloader: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        if viewModel.canShowImageView {
            ZStack {
                Image(uiImage: viewModel.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: viewModel.imageWidth, maxHeight: viewModel.imageHeight)
                    .clipped()
                    .zIndex(0)
                    .background(gradient)
                    .blur(radius: viewModel.blurRadius ?? 0, opaque: false)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
                if let downloadVM = viewModel.downloadFileVM, downloadVM.state != .completed {
                    OverlayDownloadImageButton(message: message)
                        .environmentObject(downloadVM)
                }
            }
            .onTapGesture {
                viewModel.onTap()
            }
            .clipped()
        }
    }

    private static let clearGradient = LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
    private static let emptyImageGradient = LinearGradient(
        colors: [
            Color.App.bgPrimary.opacity(0.2),
            Color.App.bgPrimary.opacity(0.3),
            Color.App.bgPrimary.opacity(0.4),
            Color.App.bgPrimary.opacity(0.5),
            Color.App.bgPrimary.opacity(0.6),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private var gradient: LinearGradient {
        let clearState = viewModel.downloadFileVM?.state == .completed || viewModel.downloadFileVM?.state == .thumbnail
        return clearState ? MessageRowImageDownloader.clearGradient : MessageRowImageDownloader.emptyImageGradient
    }
}

struct OverlayDownloadImageButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @EnvironmentObject var messageRowVM: MessageRowViewModel
    let message: Message?
    private var percent: Int64 { viewModel.downloadPercent }
    private var stateIcon: String {
        if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        if viewModel.state != .completed {
            HStack {
                ZStack {
                    iconView
                    progress
                }
                .frame(width: 26, height: 26)
                .background(Color.App.white.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius:(13)))
                sizeView
            }
            .frame(height: 30)
            .frame(minWidth: 76)
            .padding(4)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius:(18)))
            .animation(.easeInOut, value: stateIcon)
            .animation(.easeInOut, value: percent)
            .onTapGesture {
                if viewModel.state == .paused {
                    viewModel.resumeDownload()
                } else if viewModel.state == .downloading {
                    viewModel.pauseDownload()
                } else {
                    viewModel.startDownload()
                }
            }
        }
    }

    private var iconView: some View {
        Image(systemName: stateIcon)
            .resizable()
            .scaledToFit()
            .font(.system(size: 8, design: .rounded).bold())
            .frame(width: 8, height: 8)
            .foregroundStyle(Color.App.textPrimary)
    }

    private var progress: some View {
        Circle()
            .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundColor(Color.App.white)
            .rotationEffect(Angle(degrees: 270))
            .frame(width: 18, height: 18)
    }

    @ViewBuilder private var sizeView: some View {
        if let fileSize = messageRowVM.computedFileSize {
            Text(fileSize)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption2)
                .foregroundColor(Color.App.textPrimary)
        }
    }
}

struct MessageRowImageDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageDownloader()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
