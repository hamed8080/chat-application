//
//  InlineAudioPlayerView.swift
//  ChatApplication
//
//  Created by hamed on 2/20/22.
//

import Foundation
import SwiftUI
import ChatAppViewModels

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
        VStack {
            Image(systemName: !viewModel.isPlaying ? "play.circle.fill" : "pause.circle.fill")
                .resizable()
                .foregroundColor(.blue)
                .frame(width: 48, height: 48, alignment: .leading)
                .cornerRadius(24)
                .animation(.easeInOut, value: viewModel.isPlaying)
                .onTapGesture {
                    viewModel.setup(fileURL: fileURL, ext: ext, title: title, subtitle: subtitle)
                    viewModel.toggle()
                }
        }
        .padding()
    }
}
