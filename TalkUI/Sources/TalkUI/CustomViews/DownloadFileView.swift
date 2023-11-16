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
import TalkModels

public struct DownloadFileView: View {
    let viewModel: DownloadFileViewModel
    var message: Message? { viewModel.message }

    let config: DownloadFileViewConfig

    public init(viewModel: DownloadFileViewModel, config: DownloadFileViewConfig = .normal) {
        self.viewModel = viewModel
        self.config = config
    }

    public var body: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .center) {
                MutableDownloadViews(config: config)
            }
            DownloadFileStack(message: message, config: config)
        }
        .environmentObject(viewModel)
    }
}

struct MutableDownloadViews: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    var message: Message? { viewModel.message }
    let config: DownloadFileViewConfig

    var body: some View {
        switch viewModel.state {
        case .completed:
            if let iconName = message?.iconName {
                Image(systemName: iconName)
                    .resizable()
                    .foregroundStyle(config.iconColor, config.iconCircleColor)
                    .scaledToFit()
                    .frame(width: config.iconWidth, height: config.iconHeight)
            }
        case .downloading, .started, .undefined, .thumbnail, .paused:
            if message?.isFileType == true {
                DownloadFileButton(message: message, config: config)
                    .padding(.horizontal, config.showFileName ? 4 : 0)
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
    let config: DownloadFileViewConfig
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
                    .frame(width: 12, height: 12)
                    .foregroundStyle(config.iconColor)

                Circle()
                    .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundColor(config.progressColor)
                    .rotationEffect(Angle(degrees: 270))
                    .frame(width: config.circleProgressMaxWidth, height: config.circleProgressMaxWidth)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: config.iconWidth, height: config.iconHeight)
            .background(config.iconCircleColor)
            .cornerRadius(config.iconHeight / 2)
            .onTapGesture {
                if viewModel.state == .paused {
                    viewModel.resumeDownload()
                } else if viewModel.state == .downloading {
                    viewModel.pauseDownload()
                } else {
                    viewModel.startDownload()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if let fileName = message?.fileName, config.showTrailingFileName {
                    Text(fileName)
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldSubheadline)
                        .foregroundColor(.white)
                }

                if let fileZize = message?.fileMetaData?.file?.size, config.showFileSize {
                    Text(String(fileZize))
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldCaption2)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct DownloadFileStack: View {
    let message: Message?
    let config: DownloadFileViewConfig

    var body: some View {
        if !(message?.isImage ?? false) {
            VStack(alignment: .leading, spacing: 8) {
                DownloadFileName(message: message, config: config)
                DownloadFileSize(message: message, config: config)
            }
        }
    }
}

public struct DownloadFileName: View {
    let message: Message?
    let config: DownloadFileViewConfig
    var fileName: String? { message?.fileName ?? message?.fileMetaData?.file?.originalName }

    public var body: some View {
        if config.showFileName, let fileName {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(fileName)\(message?.fileExtension ?? "")")
                    .foregroundStyle(Color.App.text)
                    .font(.iransansBoldCaption)
            }
        }
    }
}

struct DownloadFileSize: View {
    let message: Message?
    let config: DownloadFileViewConfig

    var body: some View {
        if config.showFileSize, let fileSize = message?.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale), message?.isAudio == false {
            Text(fileSize)
                .multilineTextAlignment(.leading)
                .font(.iransansCaption3)
                .foregroundColor(Color.App.text)
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
            .background(Color.App.purple)
            .onAppear {
                viewModel.state = .paused
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
