//
//  MessageRowImageView.swift
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

struct MessageRowImageView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        ZStack {
            Image(uiImage: viewModel.fileState.image ?? DownloadFileManager.emptyImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: viewModel.calMessage.sizes.imageWidth, height: viewModel.calMessage.sizes.imageHeight)
                .clipped()
                .zIndex(0)
                .background(MessageRowImageView.emptyImageGradient)
                .blur(radius: viewModel.fileState.blurRadius, opaque: false)
                .clipShape(RoundedRectangle(cornerRadius:(8)))
                .onTapGesture {
                    viewModel.onTap()
                }
            let showDownload = viewModel.fileState.showDownload
            OverlayDownloadImageButton()
                .frame(width: showDownload ? nil : 0, height: showDownload ? nil : 0)
                .clipped()
                .disabled(!showDownload)
                .animation(.easeInOut, value: showDownload)

            if viewModel.fileState.isUploading {
                OverlayUploadImageButton()
            }
        }
        .padding(.top, viewModel.calMessage.sizes.paddings.fileViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
        .clipped()
        .onAppear {
            viewModel.prepareForTumbnailIfNeeded()
        }
    }

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
}

fileprivate struct OverlayDownloadImageButton: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.fileState.state != .completed {
            Button {
                viewModel.onTap()
            } label: {
                HStack {
                    ZStack {
                        iconView
                        progress
                    }
                    .frame(width: 36, height: 36)
                    .background(Color.App.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius:(18)))
                    sizeView
                }
                .frame(height: 36)
                .frame(minWidth: 76)
                .padding(4)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(24)))
            }
            .animation(.easeInOut, value: viewModel.fileState.iconState)
            .animation(.easeInOut, value: viewModel.fileState.progress)
            .buttonStyle(.borderless)
        }
    }

    private var iconView: some View {
        Image(systemName: viewModel.fileState.iconState)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .font(.system(size: 14, design: .rounded))
            .fontWeight(viewModel.fileState.state == .downloading ? .semibold : .regular)
            .frame(width: 14, height: 14)
            .foregroundStyle(Color.App.textPrimary)
    }

    private var progress: some View {
        Circle()
            .trim(from: 0.0, to: viewModel.fileState.progress)
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundColor(Color.App.white)
            .rotationEffect(Angle(degrees: 270))
            .frame(width: 34, height: 34)
            .rotateAnimtion(pause: viewModel.fileState.state == .paused)
    }

    @ViewBuilder private var sizeView: some View {
        if let fileSize = viewModel.calMessage.computedFileSize {
            Text(fileSize)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption2)
                .foregroundColor(Color.App.textPrimary)
        }
    }
}

fileprivate struct OverlayUploadImageButton: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.fileState.state != .completed {
            Button {
                viewModel.cancelUpload()
            } label: {
                HStack {
                    ZStack {
                        iconView
                        progress
                    }
                    .frame(width: 36, height: 36)
                    .background(Color.App.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius:(18)))
                    sizeView
                }
                .frame(height: 36)
                .frame(minWidth: 76)
                .padding(4)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(24)))
            }
            .animation(.easeInOut, value: viewModel.fileState.iconState)
            .animation(.easeInOut, value: viewModel.fileState.progress)
            .buttonStyle(.borderless)
        }
    }

    private var iconView: some View {
        Image(systemName: viewModel.fileState.iconState)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .font(.system(size: 8, design: .rounded).bold())
            .frame(width: 14, height: 14)
            .foregroundStyle(Color.App.textPrimary)
    }

    private var progress: some View {
        Circle()
            .trim(from: 0.0, to: viewModel.fileState.progress)
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundColor(Color.App.white)
            .rotationEffect(Angle(degrees: 270))
            .frame(width: 34, height: 34)
            .rotateAnimtion(pause: viewModel.fileState.state == .paused)
    }

    @ViewBuilder private var sizeView: some View {
        let uploadFileSize: Int64 = Int64((viewModel.message as? UploadFileMessage)?.uploadImageRequest?.data.count ?? 0)
        let realServerFileSize = viewModel.calMessage.fileMetaData?.file?.size
        if let fileSize = (realServerFileSize ?? uploadFileSize).toSizeString(locale: Language.preferredLocale) {
            Text(fileSize)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption2)
                .foregroundColor(Color.App.textPrimary)
        }
    }
}

struct MessageRowImageDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageView()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
