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
    @State private var showFullScreen = false
    public init() {}

    public var body: some View {
        VStack {
            if let player = videoPlayerVM.player {
                PlayerViewRepresentable(player: player, showFullScreen: $showFullScreen)
                    .frame(minHeight: 196)
                    .cornerRadius(12)
                    .disabled(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showFullScreen = true
            }
        }
        .padding()
        .overlay(alignment: .topLeading) {
            Text(String(localized:.init(videoPlayerVM.timerString)))
                .padding(6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .offset(x: 24, y: 24)
        }
        .overlay(alignment: .center) {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 42, height: 42)
                .overlay(alignment: .center) {
                    Image(systemName: videoPlayerVM.player?.timeControlStatus == .paused ? "play.fill" : "pause.fill")
                        .resizable()
                        .frame(width: 12, height: 12)
                }
                .onTapGesture {
                    withAnimation {
                        videoPlayerVM.toggle()
                        videoPlayerVM.animateObjectWillChange()
                    }
                }
        }
    }
}

public struct PlayerViewRepresentable: UIViewControllerRepresentable {
    var player: AVPlayer
    @Binding var showFullScreen: Bool

    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsVideoFrameAnalysis = false
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.delegate = context.coordinator
        chooseScreenType(controller)
        return controller
    }

    public func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        print("updateUIViewController->", showFullScreen)
        chooseScreenType(playerController)
    }

    private func chooseScreenType(_ controller: AVPlayerViewController) {
        print("chooseScreenType", self.showFullScreen)
        self.showFullScreen ? controller.enterFullScreen(animated: true) : controller.exitFullScreen(animated: true)
    }

    public func makeCoordinator() -> VideoCoordinator {
        Coordinator(showFullScreen: $showFullScreen)
    }

    public class VideoCoordinator: NSObject, AVPlayerViewControllerDelegate {
        var showFullScreen: Binding<Bool>

        init(showFullScreen: Binding<Bool>) {
            self.showFullScreen = showFullScreen
        }

        public func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            showFullScreen.wrappedValue = false
        }
    }
}

public extension AVPlayerViewController {
    func enterFullScreen(animated: Bool) {
        print("Enter full screen")
        perform(NSSelectorFromString("enterFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }

    func exitFullScreen(animated: Bool) {
        print("Exit full screen")
        perform(NSSelectorFromString("exitFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }
}


struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView()
            .environmentObject(VideoPlayerViewModel(fileURL: URL(filePath: "/Users/hamed/Desktop/Workspace/ios/Fanap/ChatApplication/ChatApplication/Supporting Files/webrtc_user_a.mp4"), directLink: true))
            .frame(width: 480, height: 400)
    }
}
