//
//  MessageAudioView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import Combine

final class MessageAudioView: UIView {
    private let fileNameLabel = UILabel()
    private let fileTypeLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let playerProgress = UIProgressView(progressViewStyle: .bar)
    private var cancellable: AnyCancellable?
    private let progressButton = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                      iconTint: Color.App.textPrimaryUIColor,
                                                      bgColor: Color.App.accentUIColor,
                                                      margin: 2
    )
    private let timeLabel = UILabel()
    private weak var viewModel: MessageRowViewModel?
    private var message: (any HistoryMessageProtocol)? { viewModel?.message }
    private var audioVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 5
        layer.masksToBounds = true
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight

        progressButton.translatesAutoresizingMaskIntoConstraints = false
        progressButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        progressButton.isUserInteractionEnabled = true
        progressButton.accessibilityIdentifier = "progressButtonMessageAudioView"
        progressButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addSubview(progressButton)

        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.font = UIFont.uiiransansBoldCaption2
        fileNameLabel.textAlignment = .left
        fileNameLabel.textColor = Color.App.textPrimaryUIColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.backgroundColor = .blue
        fileNameLabel.accessibilityIdentifier = "fileNameLabelMessageAudioView"
        fileNameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        addSubview(fileNameLabel)


        fileTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileTypeLabel.font = UIFont.uiiransansBoldCaption2
        fileTypeLabel.textAlignment = .left
        fileTypeLabel.textColor = Color.App.textSecondaryUIColor
        fileTypeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addSubview(fileTypeLabel)

        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor
        fileSizeLabel.accessibilityIdentifier = "fileSizeLabelMessageAudioView"
        addSubview(fileSizeLabel)

        playerProgress.translatesAutoresizingMaskIntoConstraints = false
        playerProgress.tintColor = Color.App.textPrimaryUIColor
        playerProgress.layer.cornerRadius = 1.5
        playerProgress.layer.masksToBounds = true
        playerProgress.trackTintColor = UIColor.gray.withAlphaComponent(0.3)
        playerProgress.accessibilityIdentifier = "playerProgressMessageAudioView"
        addSubview(playerProgress)


        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = Color.App.textPrimaryUIColor
        timeLabel.font = UIFont.uiiransansBoldCaption
        timeLabel.numberOfLines = 1
        timeLabel.textAlignment = .left
        timeLabel.accessibilityIdentifier = "timeLabelMessageAudioView"
        addSubview(timeLabel)

        NSLayoutConstraint.activate([
            
            progressButton.widthAnchor.constraint(equalToConstant: 36),
            progressButton.heightAnchor.constraint(equalToConstant: 36),
            progressButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            progressButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),

            fileNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            fileNameLabel.heightAnchor.constraint(equalToConstant: 20),
            fileNameLabel.leadingAnchor.constraint(equalTo: progressButton.trailingAnchor, constant: 8),
            fileNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            fileTypeLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            fileTypeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 2),
            fileTypeLabel.heightAnchor.constraint(equalToConstant: 20),

            fileSizeLabel.leadingAnchor.constraint(equalTo: fileTypeLabel.trailingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: fileTypeLabel.topAnchor),
            fileSizeLabel.heightAnchor.constraint(equalToConstant: 20),
            fileSizeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            playerProgress.widthAnchor.constraint(greaterThanOrEqualToConstant: 128),
            playerProgress.heightAnchor.constraint(equalToConstant: 3),
            playerProgress.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            playerProgress.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            playerProgress.topAnchor.constraint(equalTo: fileTypeLabel.bottomAnchor, constant: 4),

            timeLabel.leadingAnchor.constraint(equalTo: playerProgress.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: playerProgress.bottomAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            timeLabel.heightAnchor.constraint(equalToConstant: 20),

        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isAudio {
            reset()
            return
        }
        setIsHidden(false)
        self.viewModel = viewModel
        updateProgress(viewModel: viewModel)

        fileSizeLabel.text = viewModel.calMessage.computedFileSize
        fileNameLabel.text = viewModel.calMessage.fileName
        fileTypeLabel.text = viewModel.calMessage.extName
        timeLabel.text = audioTimerString()
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        viewModel?.onTap()
        if isSameFile {
            if audioVM.isPlaying {
                registerOnTap()
            } else {
                unRegisterOnTap()
            }
            if let viewModel = viewModel {
                updateProgress(viewModel: viewModel)
            }
        }
    }

    func reset() {
        setIsHidden(true)
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        let progress = viewModel.fileState.progress
        let icon = viewModel.fileState.iconState
        progressButton.animate(to: progress, systemIconName: playingIcon ?? icon)
        progressButton.setProgressVisibility(visible: canShowProgress)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        updateProgress(viewModel: viewModel)
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        updateProgress(viewModel: viewModel)
    }

    private var canShowProgress: Bool {
        viewModel?.fileState.state == .downloading || viewModel?.fileState.isUploading == true
    }

    var isSameFile: Bool {
        if audioVM.fileURL == nil { return true } // It means it has never played a audio.
        return viewModel?.calMessage.fileURL != nil && audioVM.fileURL?.absoluteString == viewModel?.calMessage.fileURL?.absoluteString
    }

    var progress: CGFloat {
        isSameFile ? min(audioVM.currentTime / audioVM.duration, 1.0) : 0
    }

    func registerOnTap() {
        cancellable = audioVM.$currentTime.sink { [weak self] newValue in
            guard let self = self else { return }
            let progress = min(audioVM.currentTime / audioVM.duration, 1.0)
            let normalized = progress.isNaN ? 0.0 : Float(progress)
            playerProgress.setProgress(normalized, animated: true)
            self.timeLabel.text = audioTimerString()
        }
    }

    public func unRegisterOnTap() {
        cancellable?.cancel()
        cancellable = nil
    }

    private func audioTimerString() -> String {
        isSameFile ? "\(audioVM.currentTime.timerString(locale: Language.preferredLocale) ?? "") / \(audioVM.duration.timerString(locale: Language.preferredLocale) ?? "")" : " " // We use space to prevent the text collapse
    }

    var playingIcon: String? {
        if !isSameFile { return nil }
        return audioVM.isPlaying ? "pause.fill" : "play.fill"
    }
}
