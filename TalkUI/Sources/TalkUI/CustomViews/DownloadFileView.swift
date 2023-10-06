//
//  DownloadFileView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AVFoundation
import Chat
import Combine
import SwiftUI
import TalkViewModels
import ChatModels
import AVKit

public struct DownloadFileView: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    let viewModel: DownloadFileViewModel
    var message: Message? { viewModel.message }
    @State var shareDownloadedFile: Bool = false
    let config: DownloadFileViewConfig

    public init(viewModel: DownloadFileViewModel, config: DownloadFileViewConfig = .normal) {
        self.viewModel = viewModel
        self.config = config
    }

    public var body: some View {
        HStack {
            ZStack(alignment: .center) {
                DownloadImagethumbnail(viewModel: viewModel)
                MutableDownloadViews(config: config)
                    .environmentObject(viewModel)
            }
        }
        .frame(maxWidth: config.maxHeight, maxHeight: config.maxHeight)
        .sheet(isPresented: $shareDownloadedFile) {
            if let fileURL = viewModel.fileURL, let message {
                ActivityViewControllerWrapper(activityItems: [fileURL], title: message.fileMetaData?.file?.originalName)
            } else {
                EmptyView()
            }
        }
        .onTapGesture {
            if message?.isImage == true {
                appOverlayVM.galleryMessage = message
            } else if message?.isVideo == true {
                // Enter to full screen
            } else if viewModel.state == .COMPLETED {
                shareDownloadedFile.toggle()
            }
        }
        .onAppear {
            if message?.isImage == true, !viewModel.isInCache, viewModel.thumbnailData == nil {
                viewModel.downloadBlurImage()
            }
        }
    }
}

struct MutableDownloadViews: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    var message: Message? { viewModel.message }
    let config: DownloadFileViewConfig

    var body: some View {
        switch viewModel.state {
        case .COMPLETED:
            if let fileURL = viewModel.fileURL, let scaledImage = fileURL.imageScale(width: 420)?.image {
                Image(cgImage: scaledImage)
                    .resizable()
                    .scaledToFill()
            } else if message?.isVideo == true, let fileURL = viewModel.fileURL {
                VideoPlayerView()
                    .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                            ext: message?.fileMetaData?.file?.mimeType?.ext,
                                                            title: message?.fileMetaData?.name,
                                                            subtitle: message?.fileMetaData?.file?.originalName ?? ""))
                    .id(fileURL)
            } else if message?.isAudio == true, let fileURL = viewModel.fileURL {
                InlineAudioPlayerView(fileURL: fileURL,
                                      ext: message?.fileMetaData?.file?.mimeType?.ext,
                                      title: message?.fileMetaData?.name,
                                      subtitle: message?.fileMetaData?.file?.originalName ?? "")
                .id(fileURL)
            } else if let iconName = message?.iconName {
                Image(systemName: iconName)
                    .resizable()
                    .padding(8)
                    .foregroundColor(config.iconColor)
                    .scaledToFit()
                    .frame(width: config.iconWidth, height: config.iconHeight)
            }
        case .DOWNLOADING, .STARTED:
            if config.showSkeleton {
                Rectangle()
                    .fill(.secondary)
                    .padding(8)
                    .frame(maxWidth: config.circleProgressMaxWidth)
                    .redacted(reason: .placeholder)
            } else {
                CircularProgressView(percent: $viewModel.downloadPercent, config: config.circleConfig)
                    .padding(8)
                    .frame(maxWidth: config.circleProgressMaxWidth)
                    .onTapGesture {
                        viewModel.pauseDownload()
                    }
            }
        case .PAUSED:
            Image(systemName: "pause.circle")
                .resizable()
                .padding(8)
                .font(.headline.weight(.thin))
                .foregroundColor(config.iconColor)
                .scaledToFit()
                .frame(width: config.iconWidth, height: config.iconHeight)
                .frame(maxWidth: config.circleProgressMaxWidth)
                .onTapGesture {
                    viewModel.resumeDownload()
                }
        case .UNDEFINED, .THUMBNAIL:
            Image(systemName: "arrow.down.circle")
                .resizable()
                .font(.headline.weight(.thin))
                .padding(8)
                .frame(width: config.iconWidth, height: config.iconHeight)
                .scaledToFit()
                .foregroundColor(config.iconColor)
                .zIndex(1)
                .onTapGesture {
                    viewModel.startDownload()
                }
        default:
            EmptyView()
        }
    }
}

struct DownloadImagethumbnail: View {
    @State var thumbnailData: Data?
    let viewModel: DownloadFileViewModel
    var message: Message? { viewModel.message }

    var body: some View {
        Image(uiImage: UIImage(data: thumbnailData ?? Data()) ?? UIImage())
            .resizable()
            .blur(radius: 5, opaque: true)
            .scaledToFill()
            .zIndex(0)
            .onReceive(viewModel.objectWillChange) { _ in
                if viewModel.thumbnailData != self.thumbnailData,
                   message?.isImage == true,
                   viewModel.state != .COMPLETED
                {
                    self.thumbnailData = viewModel.thumbnailData
                }
            }
    }
}

struct DownloadFileView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadFileView(viewModel: DownloadFileViewModel(message: Message(message: "Hello")))
    }
}
