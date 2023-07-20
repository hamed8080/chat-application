//
//  VideoPlayerView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/26/21.
//

import Foundation
import AVKit
import SwiftUI
import ChatAppViewModels

public struct VideoPlayerView: View {
    @EnvironmentObject var videoPlayerVM: VideoPlayerViewModel

    public var body: some View {
        VStack {
            if let player = videoPlayerVM.player {
                PlayerViewRepresentable(player: player)
                    .frame(minHeight: 196)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

}

public class AppVideoPlayerController: AVPlayerViewController {

}

public struct PlayerViewRepresentable: UIViewControllerRepresentable {
    var player: AVPlayer

    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AppVideoPlayerController()
        controller.player = player
        return controller
    }
    public func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {}
}
