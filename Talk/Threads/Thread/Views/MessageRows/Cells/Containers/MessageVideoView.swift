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

final class MessageVideoView: UIView, AVPlayerViewControllerDelegate {
    private var playerVC: AVPlayerViewController?
    @HistoryActor private var videoPlayerVM: VideoPlayerViewModel?
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let playOverlayView = UIView()
    private let playIcon: UIImageView = UIImageView()
    private static let playIcon: UIImage = UIImage(systemName: "play.fill")!
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.whiteUIColor,
                                                      lineWidth: 1,
                                                      iconSize: .init(width: 12, height: 12),
                                                      margin: 2
    )
    private weak var viewModel: MessageRowViewModel?
    private var message: (any HistoryMessageProtocol)? { viewModel?.message }

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4
        layer.masksToBounds = true
        backgroundColor = UIColor.black
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageVideoView"
        addSubview(fileSizeLabel)

        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.accessibilityIdentifier = "fileNameLabelMessageVideoView"
        addSubview(fileNameLabel)

        fileTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor
        fileTypeLabel.accessibilityIdentifier = "fileTypeLabelMessageVideoView"
        addSubview(fileTypeLabel)

        playIcon.translatesAutoresizingMaskIntoConstraints = false
        playIcon.setIsHidden(true)
        playIcon.contentMode = .scaleAspectFit
        playIcon.image = MessageVideoView.playIcon
        playIcon.tintColor = Color.App.whiteUIColor
        playIcon.accessibilityIdentifier = "playIconMessageVideoView"
        addSubview(playIcon)

        playOverlayView.translatesAutoresizingMaskIntoConstraints = false
        playOverlayView.backgroundColor = .clear
        playOverlayView.accessibilityIdentifier = "playOverlayViewMessageVideoView"
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onTap))
        playOverlayView.addGestureRecognizer(tapGesture)
        addSubview(playOverlayView)

        progressButton.translatesAutoresizingMaskIntoConstraints = false
        progressButton.accessibilityIdentifier = "progressButtonMessageVideoView"
        addSubview(progressButton)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: viewModel?.calMessage.sizes.width ?? 320),
            heightAnchor.constraint(equalToConstant: 196),
            playOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playOverlayView.topAnchor.constraint(equalTo: topAnchor),
            playOverlayView.heightAnchor.constraint(equalTo: heightAnchor),
            progressButton.widthAnchor.constraint(equalToConstant: 24),
            progressButton.heightAnchor.constraint(equalToConstant: 24),
            progressButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            progressButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            fileNameLabel.trailingAnchor.constraint(equalTo: progressButton.leadingAnchor, constant: -4),
            fileNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            fileNameLabel.centerYAnchor.constraint(equalTo: progressButton.centerYAnchor),
            fileTypeLabel.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor, constant: 0),
            fileTypeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 2),
            fileSizeLabel.trailingAnchor.constraint(equalTo: fileTypeLabel.leadingAnchor, constant: -4),
            fileSizeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 2),
            playIcon.widthAnchor.constraint(equalToConstant: 36),
            playIcon.heightAnchor.constraint(equalToConstant: 36),
            playIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isVideo {
            reset()
            return
        }
        setIsHidden(false)
        self.viewModel = viewModel
        if let url = viewModel.calMessage.fileURL {
            prepareUIForPlayback(url: url)
        } else {
            prepareUIForDownload()
        }
        updateProgress(viewModel: viewModel)
        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileTypeLabel.text = viewModel.calMessage.extName
    }

    private func prepareUIForPlayback(url: URL) {
        showDownloadProgress(show: false)
        playIcon.setIsHidden(false)
        Task {
            await makeViewModel(url: url, message: message)
            if let player = await videoPlayerVM?.player {
                setVideo(player: player)
            }
        }
    }

    private func prepareUIForDownload() {
        playIcon.setIsHidden(true)
        showDownloadProgress(show: true)
    }

    private func showDownloadProgress(show: Bool) {
        progressButton.setIsHidden(!show)
        progressButton.setProgressVisibility(visible: show)
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        let progress = viewModel.fileState.progress
        progressButton.animate(to: progress, systemIconName: viewModel.fileState.iconState)
        progressButton.setProgressVisibility(visible: canShowProgress)
    }

    private var canShowProgress: Bool {
        viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        updateProgress(viewModel: viewModel)
        if let fileURL = viewModel.calMessage.fileURL {
            prepareUIForPlayback(url: fileURL)
        }
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        updateProgress(viewModel: viewModel)
        if let fileURL = viewModel.calMessage.fileURL {
            prepareUIForPlayback(url: fileURL)
        }
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        if viewModel?.calMessage.fileURL != nil {
            Task {
                await videoPlayerVM?.toggle()
            }
            enterFullScreen(animated: true)
        } else {
            // Download file
            viewModel?.onTap()
        }
    }

    func reset() {
        setIsHidden(true)
    }

    @MainActor
    private func setVideo(player: AVPlayer) {
        if playerVC == nil {
            playerVC = AVPlayerViewController()
        }
        playerVC?.player = player
        playerVC?.showsPlaybackControls = false
        playerVC?.allowsVideoFrameAnalysis = false
        playerVC?.entersFullScreenWhenPlaybackBegins = true
        playerVC?.delegate = self
        addPlayerViewToView()
    }

    private func addPlayerViewToView() {
        let rootVC = viewModel?.threadVM?.delegate as? UIViewController
        if let rootVC = rootVC, let playerVC = playerVC, let view = playerVC.view {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(view, at: 0)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor),
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

    @HistoryActor
    private func makeViewModel(url: URL, message: (any HistoryMessageProtocol)?) {
        if url.absoluteString == videoPlayerVM?.fileURL.absoluteString ?? "" { return }
        self.videoPlayerVM = VideoPlayerViewModel(fileURL: url,
                             ext: message?.fileMetaData?.file?.mimeType?.ext,
                             title: message?.fileMetaData?.name,
                             subtitle: message?.fileMetaData?.file?.originalName ?? "")
    }
}
