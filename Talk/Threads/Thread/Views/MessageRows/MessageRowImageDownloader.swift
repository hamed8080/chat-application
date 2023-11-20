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

struct MessageRowImageDownloader: View {
    @State private var image: UIImage = .init()
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    static let clearGradient = LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
    static let emptyImageGradient = LinearGradient(colors: [Color.App.bgInput, Color.App.bgInputDark], startPoint: .top, endPoint: .bottom)

    var body: some View {
        if message.isImage, let downloadVM = viewModel.downloadFileVM {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: max(128, (viewModel.maxWidth ?? 0)) - (8 + MessageRowBackground.tailSize.width),
                           height: min(320, max(128, (viewModel.maxWidth ?? 0))))
                    .clipped()
                    .blur(radius: downloadVM.state == .thumbnail ? 16 : 0, opaque: false)
                    .zIndex(0)
                    .background(
                        downloadVM.fileURL != nil || downloadVM.state == .thumbnail ? MessageRowImageDownloader.clearGradient : MessageRowImageDownloader.emptyImageGradient
                    )
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
                    .task {
                        if let emptyImage = UIImage(named: "empty_image"), downloadVM.thumbnailData == nil && downloadVM.state != .completed {
                            image = emptyImage
                        }

                        if downloadVM.state == .thumbnail, let data = downloadVM.thumbnailData, let thumbnailImage = UIImage(data: data) {
                            image = thumbnailImage
                        }

                        if !downloadVM.isInCache, downloadVM.thumbnailData == nil {
                            downloadVM.downloadBlurImage(quality: 0.5, size: .SMALL)
                        }

                        if let cgImage = downloadVM.fileURL?.imageScale(width: 420)?.image {
                            image = UIImage(cgImage: cgImage)
                        }
                    }
                    .onReceive(downloadVM.objectWillChange) { newValue in
                        if let data = downloadVM.thumbnailData, let thumbnailImage = UIImage(data: data) {
                            image = thumbnailImage
                        }

                        if let cgImage = downloadVM.fileURL?.imageScale(width: 420)?.image {
                            image = UIImage(cgImage: cgImage)
                        }
                    }
                if downloadVM.state != .completed {
                    OverlayDownloadImageButton(message: message, config: .normal)
                        .environmentObject(downloadVM)
                }
            }
            .onTapGesture {
                AppState.shared.objectsContainer.appOverlayVM.galleryMessage = message
            }
        }
    }
}

struct OverlayDownloadImageButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    let message: Message?
    let config: DownloadFileViewConfig
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
                    .foregroundStyle(Color.App.text)

                Circle()
                    .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.App.white)
                    .rotationEffect(Angle(degrees: 270))
                    .frame(width: 18, height: 18)
            }
            .frame(width: 26, height: 26)
            .background(Color.App.white.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius:(13)))

            if let fileSize = message?.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) {
                Text(fileSize)
                    .multilineTextAlignment(.leading)
                    .font(.iransansBoldCaption2)
                    .foregroundColor(Color.App.text)
            }
        }
        .frame(height: 30)
        .frame(minWidth: 76)
        .padding(4)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius:(18)))
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

struct MessageRowImageDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageDownloader(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
