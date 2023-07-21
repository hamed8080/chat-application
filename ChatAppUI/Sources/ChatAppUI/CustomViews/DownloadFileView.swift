//
//  DownloadFileView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AVFoundation
import Chat
import Combine
import SwiftUI
import ChatAppViewModels
import ChatModels
import AVKit

public struct DownloadFileView: View {
    let viewModel: DownloadFileViewModel
    var message: Message { viewModel.message }
    @State var shareDownloadedFile: Bool = false
    @State var presentViewGallery = false

    public init(viewModel: DownloadFileViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack {
            ZStack(alignment: .center) {
                MutableDownloadViews()
                    .environmentObject(viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $shareDownloadedFile) {
            if let fileURL = viewModel.fileURL {
                ActivityViewControllerWrapper(activityItems: [fileURL], title: message.fileMetaData?.file?.originalName)
            } else {
                EmptyView()
            }
        }
        .onTapGesture {
            if message.isImage {
                presentViewGallery = true
            } else if message.isVideo {
                // Enter to full screen
            } else if viewModel.state == .COMPLETED {
                shareDownloadedFile.toggle()
            }
        }
        .fullScreenCover(isPresented: $presentViewGallery) {
            GalleryView(viewModel: GalleryViewModel(message: message))
                .id(message.id)
        }
        .onAppear {
            if message.isImage, !viewModel.isInCache, viewModel.tumbnailData == nil {
                viewModel.downloadBlurImage()
            }
        }
    }
}

struct MutableDownloadViews: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    var message: Message { viewModel.message }

    var body: some View {
        switch viewModel.state {
        case .COMPLETED:
            if let fileURL = viewModel.fileURL, let scaledImage = fileURL.imageScale(width: 420)?.image {
                Image(cgImage: scaledImage)
                    .resizable()
                    .scaledToFit()
            } else if message.isVideo, let fileURL = viewModel.fileURL {
                VideoPlayerView()
                    .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                            ext: message.fileMetaData?.file?.mimeType?.ext,
                                                            title: message.fileMetaData?.name,
                                                            subtitle: message.fileMetaData?.file?.originalName ?? ""))
                    .id(fileURL)
            } else if message.isAudio, let fileURL = viewModel.fileURL {
                InlineAudioPlayerView(fileURL: fileURL,
                                      ext: message.fileMetaData?.file?.mimeType?.ext,
                                      title: message.fileMetaData?.name,
                                      subtitle: message.fileMetaData?.file?.originalName ?? "")
                .id(fileURL)
            } else {
                Image(systemName: message.iconName)
                    .resizable()
                    .padding()
                    .foregroundColor(.iconColor.opacity(0.8))
                    .scaledToFit()
                    .frame(width: 64, height: 64)

            }
        case .DOWNLOADING, .STARTED:
            CircularProgressView(percent: $viewModel.downloadPercent)
                .padding()
                .frame(maxWidth: 128)
                .onTapGesture {
                    viewModel.pauseDownload()
                }
        case .PAUSED:
            Image(systemName: "pause.circle")
                .resizable()
                .padding()
                .font(.headline.weight(.thin))
                .foregroundColor(.indigo)
                .scaledToFit()
                .frame(width: 64, height: 64)
                .frame(maxWidth: 128)
                .onTapGesture {
                    viewModel.resumeDownload()
                }
        case .UNDEFINED, .THUMBNAIL:
            if message.isImage, let data = viewModel.tumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .blur(radius: 5, opaque: true)
                    .scaledToFit()
                    .zIndex(0)
            }

            Image(systemName: "arrow.down.circle")
                .resizable()
                .font(.headline.weight(.thin))
                .padding(8)
                .frame(width: 48, height: 48)
                .scaledToFit()
                .foregroundColor(.indigo)
                .zIndex(1)
                .onTapGesture {
                    viewModel.startDownload()
                }
        default:
            EmptyView()
        }
    }
}

struct DownloadFileView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadFileView(viewModel: DownloadFileViewModel(message: Message(message: "Hello")))
    }
}
