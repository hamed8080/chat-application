//
//  InlineAudioPlayerView.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import Foundation
import SwiftUI
import TalkViewModels
import ChatModels

public struct InlineAudioPlayerView: View {
    public let message: Message?
    public let fileURL: URL
    public let ext: String?
    public var title: String?
    public var subtitle: String
    public var config: DownloadFileViewConfig
    @EnvironmentObject var viewModel: AVAudioPlayerViewModel
    var isSameFile: Bool { viewModel.fileURL?.absoluteString == fileURL.absoluteString }

    public init(message: Message?, fileURL: URL, ext: String?, title: String? = nil, subtitle: String, config: DownloadFileViewConfig) {
        self.message = message
        self.fileURL = fileURL
        self.ext = ext
        self.title = title
        self.subtitle = subtitle
        self.config = config
    }

    public var body: some View {
        ZStack {
            Image(systemName: viewModel.isPlaying && isSameFile ? "pause.fill" : "play.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(config.iconColor)
        }
        .frame(width: config.iconWidth, height: config.iconHeight)
        .background(config.iconCircleColor)
        .clipShape(RoundedRectangle(cornerRadius: config.iconHeight / 2))
        .onTapGesture {
            viewModel.setup(message: message, fileURL: fileURL, ext: ext, title: title, subtitle: subtitle)
            viewModel.toggle()
        }
    }
}
