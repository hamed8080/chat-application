//
//  MessageImageView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels
import Chat

final class MessageImageView: UIImageView {
    private let stack = UIStackView()
    private let fileSizeLabel = UILabel()
    private let progressView = CircleProgressButton(progressColor: Color.App.whiteUIColor,
                                                    iconTint: Color.App.whiteUIColor,
                                                    margin: 2)
    private weak var viewModel: MessageRowViewModel?
    private var effectView: UIVisualEffectView!
    private var widthConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 6
        layer.masksToBounds = true
        contentMode = .scaleAspectFit

        progressView.translatesAutoresizingMaskIntoConstraints = false

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.frame = bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.isUserInteractionEnabled = false
        addSubview(effectView)
        bringSubviewToFront(effectView)

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.addArrangedSubview(progressView)
        stack.addArrangedSubview(fileSizeLabel)
        stack.backgroundColor = .white.withAlphaComponent(0.2)
        stack.layoutMargins = .init(horizontal: 4, vertical: 4)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layer.cornerRadius = 18
        stack.isUserInteractionEnabled = false

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tapGesture)

        addSubview(stack)

        widthConstraint = widthAnchor.constraint(equalToConstant: 0)
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            widthConstraint,
            heightConstraint,
            effectView.widthAnchor.constraint(equalTo: widthAnchor),
            effectView.heightAnchor.constraint(equalTo: heightAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 32),
            progressView.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isImage {
            reset()
            return
        }
        setIsHidden(false)
        self.viewModel = viewModel
        let state = viewModel.fileState.state
        let canShow = state != .completed
        if let fileURL = viewModel.calMessage.fileURL {
            setImage(fileURL: fileURL)
        } else {
            setPreloadImage(viewModel: viewModel)
        }
        stack.setIsHidden(!canShow)
        effectView.setIsHidden(!canShow)

        if state != .completed {
            let progress = viewModel.fileState.progress
            progressView.animate(to: progress, systemIconName: viewModel.fileState.iconState)
        }

        if viewModel.calMessage.computedFileSize != fileSizeLabel.text {
            fileSizeLabel.text = viewModel.calMessage.computedFileSize
        }

        if !viewModel.fileState.isUploading, viewModel.calMessage.rowType.isImage, state != .downloading, state != .completed && state != .thumbnailDownloaing, state != .thumbnail {
            viewModel.onTap() // Download thumbnail
        }

        if viewModel.calMessage.rowType.isImage {
            widthConstraint.constant = (viewModel.calMessage.sizes.imageWidth ?? 128) - 8 // -8 for parent stack view margin
            heightConstraint.constant = viewModel.calMessage.sizes.imageHeight ?? 128
        } else {
            widthConstraint.constant = 0
            heightConstraint.constant = 0
        }
    }

    private func setImage(fileURL: URL) {
        Task { @HistoryActor in
            if let scaledImage = fileURL.imageScale(width: 300)?.image {
                let image = scaledImage
                await MainActor.run {
                    self.image = UIImage(cgImage: image)
                }
            }
        }
    }

    // Thumbnail or placeholder image
    private func setPreloadImage(viewModel: MessageRowViewModel) {
        guard let image = viewModel.fileState.preloadImage else { return }
        self.image = image
    }

    @objc func onTap(_ sender: UIGestureRecognizer) {
        viewModel?.onTap()
    }

    func reset() {
        setIsHidden(true)
        stack.setIsHidden(true)
        effectView.setIsHidden(true)
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        let progress = viewModel.fileState.progress
        progressView.animate(to: progress, systemIconName: viewModel.fileState.iconState)
        progressView.setProgressVisibility(visible: viewModel.fileState.state != .completed)
    }

    public func updateThumbnail(viewModel: MessageRowViewModel) {
        setPreloadImage(viewModel: viewModel)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        if let fileURL = viewModel.calMessage.fileURL {
            updateProgress(viewModel: viewModel)
            stack.setIsHidden(true)
            effectView.setIsHidden(true)
            setImage(fileURL: fileURL)
        }
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        if let fileURL = viewModel.calMessage.fileURL {
            updateProgress(viewModel: viewModel)
            stack.setIsHidden(true)
            effectView.setIsHidden(true)
            setImage(fileURL: fileURL)
        }
    }
}
