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
            } else if viewModel.state == .completed {
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
        case .completed:
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
        case .downloading, .started, .undefined, .thumbnail, .paused:
            if message?.isImage == true {
                OverlayDownloadImageButton(message: message)
            } else if message?.isFileType == true {
                DownloadFileButton(message: message)
            }
        default:
           EmptyView()
        }
    }
}

struct DownloadFileButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    let message: Message?
    var percent: Int64 { viewModel.downloadPercent }
    var stateIcon: String {
        if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        HStack {
            ZStack {
                Image(systemName: "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.purple)

                Circle()
                    .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.purple)
                    .rotationEffect(Angle(degrees: 270))
                    .frame(width: 28, height: 28)
            }
            .frame(width: 36, height: 36)
            .background(Color.white)
            .cornerRadius(18)
            .onTapGesture {
                if viewModel.state == .paused {
                    viewModel.resumeDownload()
                } else if viewModel.state == .downloading{
                    viewModel.pauseDownload()
                } else {
                    viewModel.startDownload()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if let fileName = message?.fileName {
                    Text(fileName)
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldSubheadline)
                        .foregroundColor(.white)
                }

                if let fileZize = message?.fileMetaData?.file?.size {
                    Text(String(fileZize))
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldCaption2)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct OverlayDownloadImageButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    let message: Message?
    var percent: Int64 { viewModel.downloadPercent }
    var stateIcon: String {
        if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        HStack {
            ZStack {
                Image(systemName: stateIcon)
                    .resizable()
                    .scaledToFit()
                    .font(.system(size: 8, design: .rounded).bold())
                    .frame(width: 8, height: 8)
                    .foregroundStyle(Color.white)

                Circle()
                    .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.white)
                    .rotationEffect(Angle(degrees: 270))
                    .frame(width: 18, height: 18)
            }
            .frame(width: 26, height: 26)
            .background(Color.white.opacity(0.3))
            .cornerRadius(13)

            if let fileSize = message?.fileMetaData?.file?.size?.toSizeString {
                Text(fileSize)
                    .multilineTextAlignment(.leading)
                    .font(.iransansBoldCaption2)
                    .foregroundColor(.hintText)
            }
        }
        .frame(height: 30)
        .frame(minWidth: 76)
        .padding(4)
        .background(.thinMaterial)
        .cornerRadius(18)
        .onTapGesture {
            if viewModel.state == .paused {
                viewModel.resumeDownload()
            } else if viewModel.state == .downloading{
                viewModel.pauseDownload()
            } else {
                viewModel.startDownload()
            }
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
            .blur(radius: 16, opaque: false)
            .scaledToFill()
            .zIndex(0)
            .onReceive(viewModel.objectWillChange) { _ in
                if viewModel.thumbnailData != self.thumbnailData,
                   message?.isImage == true,
                   viewModel.state != .completed
                {
                    self.thumbnailData = viewModel.thumbnailData
                }
            }
            .onAppear {
                thumbnailData = viewModel.thumbnailData
            }
    }
}

struct DownloadFileView_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel: DownloadFileViewModel

        init() {
            let metadata = "{\"name\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11\",\"file\": {\"hashCode\": \"UJMUIT4M194C5WLJ\",\"mimeType\": \"image/png\",\"fileHash\": \"UJMUIT4M194C5WLJ\",\"actualWidth\": 1290,\"actualHeight\": 2796,\"parentHash\": \"6MIPH7UM1P7OIZ2L\",\"size\": 1569454,\"link\": \"https://podspace.pod.ir/api/images/UJMUIT4M194C5WLJ?checkUserGroupAccess=true\",\"name\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11\",\"originalName\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11.png\"},\"fileHash\": \"UJMUIT4M194C5WLJ\"}"
            let message = Message(message: "Please download this file.",
                                  messageType: .file,
                                  metadata: metadata.string)
            let viewModel = DownloadFileViewModel(message: message)
            _viewModel = StateObject(wrappedValue: viewModel)
        }

        var body: some View {
            ZStack {
                DownloadFileView(viewModel: viewModel)
                    .environmentObject(AppOverlayViewModel())
            }
            .background(Color.purple.gradient)
            .onAppear {
                viewModel.state = .paused
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
