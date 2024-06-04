//
//  MessageVideoView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import AVKit
import Chat

final class MessageVideoView: UIStackView, AVPlayerViewControllerDelegate {
    private var playerVC: AVPlayerViewController?
    private var videoPlayerVM: VideoPlayerViewModel?
    private let vStack = UIStackView()
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let downloadHStack = UIStackView()
    private let playOverlayView = UIView()
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.textPrimaryUIColor,
                                                      bgColor: Color.App.accentUIColor
    )
    private weak var viewModel: MessageRowViewModel?
    private var message: (any HistoryMessageProtocol)? { viewModel?.message }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = .init(top: 8, left: 8, bottom: 0, right: 0)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        isLayoutMarginsRelativeArrangement = true

        progressButton.translatesAutoresizingMaskIntoConstraints = false

        axis = .vertical
        spacing = 0

        downloadHStack.axis = .horizontal
        downloadHStack.spacing = 8

        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 4

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor

        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle

        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor

        let typeSizeHStack = UIStackView()
        typeSizeHStack.axis = .horizontal
        typeSizeHStack.spacing = 4

        typeSizeHStack.addArrangedSubview(fileTypeLabel)
        typeSizeHStack.addArrangedSubview(fileSizeLabel)

        vStack.addArrangedSubview(fileNameLabel)
        vStack.addArrangedSubview(typeSizeHStack)

        downloadHStack.addArrangedSubview(progressButton)
        downloadHStack.addArrangedSubview(vStack)

        addArrangedSubview(downloadHStack)

        progressButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        progressButton.isUserInteractionEnabled = true

        playOverlayView.translatesAutoresizingMaskIntoConstraints = false
        playOverlayView.backgroundColor = .clear
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onTap))
        playOverlayView.addGestureRecognizer(tapGesture)
        addSubview(playOverlayView)

        NSLayoutConstraint.activate([
            playOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playOverlayView.topAnchor.constraint(equalTo: topAnchor),
            playOverlayView.heightAnchor.constraint(equalTo: heightAnchor),
            progressButton.widthAnchor.constraint(equalToConstant: 36),
            progressButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isVideo {
            reset()
            return
        }
        isHidden = false
        semanticContentAttribute = viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight
        self.viewModel = viewModel
        let progress = viewModel.fileState.progress

        if let fileURL = getURL() {
            layoutMargins = .init(all: 0)
            downloadHStack.isHidden = true
            makeViewModel(url: fileURL)
            if let player = videoPlayerVM?.player {
                setVideo(player: player)
            }
            bringSubviewToFront(playOverlayView)
        } else if viewModel.fileState.state != .completed {
            downloadHStack.isHidden = false
            progressButton.animate(to: progress, systemIconName: viewModel.fileState.iconState)
            progressButton.setProgressVisibility(visible: viewModel.fileState.state != .completed)
        } else if let url = viewModel.fileState.url {
            layoutMargins = .init(all: 0)
            downloadHStack.isHidden = true
            makeViewModel(url: url)
            if let player = videoPlayerVM?.player {
                setVideo(player: player)
            }
            bringSubviewToFront(playOverlayView)
        }
        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileTypeLabel.text = viewModel.calMessage.extName
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        videoPlayerVM?.toggle()
        enterFullScreen(animated: true)
    }

    func reset() {
        if !isHidden {
            isHidden = true
        }
    }

    private func setVideo(player: AVPlayer) {
        if playerVC == nil {
            playerVC = AVPlayerViewController()
        }
        playerVC?.player = player
        playerVC?.showsPlaybackControls = false
        playerVC?.allowsVideoFrameAnalysis = false
        playerVC?.entersFullScreenWhenPlaybackBegins = true
        playerVC?.delegate = self
        let rootVC = viewModel?.threadVM?.delegate as? UIViewController
        if let rootVC = rootVC, let playerVC = playerVC, let view = playerVC.view {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.addArrangedSubview(view)
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: 320),
                view.heightAnchor.constraint(equalToConstant: 196),
            ])
            rootVC.addChild(playerVC)
            playerVC.didMove(toParent: rootVC)
        }
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
        playerVC?.showsPlaybackControls = true
    }
    public func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        playerVC?.showsPlaybackControls = false
    }

    func enterFullScreen(animated: Bool) {
        playerVC?.perform(NSSelectorFromString("enterFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }

    func exitFullScreen(animated: Bool) {
        playerVC?.perform(NSSelectorFromString("exitFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }

    private func makeViewModel(url: URL) {
        if url.absoluteString == videoPlayerVM?.fileURL.absoluteString ?? "" { return }
        self.videoPlayerVM = VideoPlayerViewModel(fileURL: url,
                             ext: message?.fileMetaData?.file?.mimeType?.ext,
                             title: message?.fileMetaData?.name,
                             subtitle: message?.fileMetaData?.file?.originalName ?? "")
    }

    public func getURL() -> URL? {
        let urlString = viewModel?.calMessage.fileMetaData?.file?.link
        if let urlString = urlString, let url = URL(string: urlString) {
            if ChatManager.activeInstance?.file.isFileExist(url) == false { return nil }
            let fileURL = ChatManager.activeInstance?.file.filePath(url)
            return fileURL
        }
        return nil
    }
}
