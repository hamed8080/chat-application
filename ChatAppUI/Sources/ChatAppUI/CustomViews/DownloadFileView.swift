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
    @EnvironmentObject var downloadFileVM: DownloadFileViewModel
    @State var shareDownloadedFile: Bool = false
    let message: Message
    @State var presentViewGallery = false

    public init(message: Message, placeHolder: Data? = nil) {
        self.message = message
        if let placeHolder = placeHolder {
            downloadFileVM.data = placeHolder
        }
    }

    public var body: some View {
        HStack {
            ZStack(alignment: .center) {
                switch downloadFileVM.state {
                case .COMPLETED:
                    if let fileURL = downloadFileVM.fileURL, let scaledImage = fileURL.imageScale(width: 420)?.image {
                        Image(cgImage: scaledImage)
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                presentViewGallery = true
                            }
                    } else if message.isVideo, let fileURL = downloadFileVM.fileURL {
                        VideoPlayerView()
                            .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                                    ext: message.fileMetaData?.file?.mimeType?.ext,
                                                                    title: message.fileMetaData?.name,
                                                                    subtitle: message.fileMetaData?.file?.originalName ?? ""))
                            .id(fileURL)
                    } else if message.isAudio, let fileURL = downloadFileVM.fileURL {
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
                            .onTapGesture {
                                shareDownloadedFile.toggle()
                            }
                    }
                case .DOWNLOADING, .STARTED:
                    CircularProgressView(percent: $downloadFileVM.downloadPercent)
                        .padding()
                        .frame(maxWidth: 128)
                        .onTapGesture {
                            downloadFileVM.pauseDownload()
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
                            downloadFileVM.resumeDownload()
                        }
                case .UNDEFINED, .THUMBNAIL:
                    if message.isImage, let data = downloadFileVM.tumbnailData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .blur(radius: 5, opaque: true)
                            .scaledToFit()
                            .zIndex(0)
                            .onTapGesture {
                                presentViewGallery = true
                            }
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
                            downloadFileVM.startDownload()
                        }
                default:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut, value: downloadFileVM.state)
        .animation(.easeInOut, value: downloadFileVM.data)
        .animation(.easeInOut, value: downloadFileVM.downloadPercent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $shareDownloadedFile) {
            if let fileURL = downloadFileVM.fileURL {
                ActivityViewControllerWrapper(activityItems: [fileURL], title: message.fileMetaData?.file?.originalName)
            } else {
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $presentViewGallery) {
            GalleryView()
                .id(message.id)
                .environmentObject(GalleryViewModel(message: message))
        }
        .onAppear {
            downloadFileVM.setMessage(message: message)
            if message.isImage, !downloadFileVM.isInCache, downloadFileVM.tumbnailData == nil {
                downloadFileVM.downloadBlurImage()
            }
        }
    }
}

struct DownloadFileView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadFileView(message: Message(message: "Hello"), placeHolder: UIImage(named: "avatar")?.pngData())
    }
}
