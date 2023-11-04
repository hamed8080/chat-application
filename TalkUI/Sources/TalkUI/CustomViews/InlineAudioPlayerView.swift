//
//  InlineAudioPlayerView.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import Foundation
import SwiftUI
import TalkViewModels

public struct InlineAudioPlayerView: View {
    public let fileURL: URL
    public let ext: String?
    public var title: String?
    public var subtitle: String
    @EnvironmentObject var viewModel: AVAudioPlayerViewModel

    public init(fileURL: URL, ext: String?, title: String? = nil, subtitle: String) {
        self.fileURL = fileURL
        self.ext = ext
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        Image(systemName: !viewModel.isPlaying ? "play.circle.fill" : "pause.circle.fill")
            .resizable()
            .foregroundStyle(Color.App.white, Color.App.primary)
            .frame(width: 36, height: 36, alignment: .leading)
            .cornerRadius(18)
            .animation(.easeInOut, value: viewModel.isPlaying)
            .onTapGesture {
                viewModel.setup(fileURL: fileURL, ext: ext, title: title, subtitle: subtitle)
                viewModel.toggle()
            }
    }
}
