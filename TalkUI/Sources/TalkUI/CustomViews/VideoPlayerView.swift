//
//  VideoPlayerView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 11/26/21.
//

import Foundation
import AVKit
import SwiftUI
import TalkViewModels
import OSLog

fileprivate let logger = Logger(subsystem: "TalkUI", category: "VideoPlayerView")
//public struct VideoPlayerView: View {
//
//    @EnvironmentObject var videoPlayerVM: VideoPlayerViewModel
//    @State private var showFullScreen = false
//    public init() {}
//
//    public var body: some View {
//        VStack {
//            if let player = videoPlayerVM.player {
//                PlayerViewRepresentable(player: player, showFullScreen: $showFullScreen)
//                    .frame(maxWidth: 320, minHeight: 196)
//                    .clipShape(RoundedRectangle(cornerRadius:(8)))
//                    .disabled(true)
//            }
//        }
//        .contentShape(Rectangle())
//        .onTapGesture {
//            withAnimation {
//                showFullScreen = true
//            }
//        }
//        .overlay(alignment: .topLeading) {
//            Text(String(localized:.init(videoPlayerVM.timerString)))
//                .padding(6)
//                .background(.ultraThinMaterial)
//                .clipShape(RoundedRectangle(cornerRadius:(8)))
//                .offset(x: 8, y: 8)
//                .font(.iransansCaption)
//        }
//        .overlay(alignment: .center) {
//            Circle()
//                .fill(.ultraThinMaterial)
//                .frame(width: 42, height: 42)
//                .overlay(alignment: .center) {
//                    Image(systemName: videoPlayerVM.player?.timeControlStatus == .paused ? "play.fill" : "pause.fill")
//                        .resizable()
//                        .frame(width: 12, height: 12)
//                }
//                .onTapGesture {
//                    withAnimation {
//                        videoPlayerVM.toggle()
//                        videoPlayerVM.animateObjectWillChange()
//                    }
//                }
//        }
//    }
//}

public final class VideoPlayerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 196),
        ])
    }
    
    public func setValues(viewModel: MessageRowViewModel) {
        guard let fileURL = viewModel.downloadFileVM?.fileURL else { return }
        let videoVM = VideoPlayerViewModel(fileURL: fileURL,
                             ext: viewModel.fileMetaData?.file?.mimeType?.ext,
                             title: viewModel.fileMetaData?.name,
                             subtitle: viewModel.fileMetaData?.file?.originalName ?? "")
        if let player = videoVM.player {

        }
    }
}

public struct VideoPlayerViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    public func makeUIView(context: Context) -> some UIView {
        let view = VideoPlayerView()
        view.setValues(viewModel: viewModel)
        return view
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

public struct PlayerViewRepresentable: UIViewControllerRepresentable {
    var player: AVPlayer
    @Binding var showFullScreen: Bool

    public init(player: AVPlayer, showFullScreen: Binding<Bool>) {
        self.player = player
        self._showFullScreen = showFullScreen
    }

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
#if DEBUG
        logger.info("updateUIViewController-> \(showFullScreen)")
#endif
        chooseScreenType(playerController)
    }

    private func chooseScreenType(_ controller: AVPlayerViewController) {
#if DEBUG
        logger.info("chooseScreenType \(self.showFullScreen)")
#endif
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
#if DEBUG
        logger.info("Enter full screen")
#endif
        perform(NSSelectorFromString("enterFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }

    func exitFullScreen(animated: Bool) {
        logger.info("Exit full screen")
        perform(NSSelectorFromString("exitFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }
}


struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = VideoPlayerViewModel(fileURL: URL(filePath: "/Users/hamed/Desktop/Workspace/ios/Fanap/Talk/Talk/Supporting Files/webrtc_user_a.mp4"), directLink: true)
        VideoPlayerViewWapper(viewModel: .init(message: .init(), viewModel: .init(thread: .init())))
            .frame(width: 480, height: 400)
    }
}
