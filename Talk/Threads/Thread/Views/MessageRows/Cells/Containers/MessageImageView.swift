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
    private let progressView = CircleProgressButton(progressColor: Color.App.whiteUIColor, iconTint: Color.App.whiteUIColor)
    private weak var viewModel: MessageRowViewModel?
    private var effectView: UIVisualEffectView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 6
        layer.masksToBounds = true
        contentMode = .scaleAspectFit

        stack.translatesAutoresizingMaskIntoConstraints = false

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.isUserInteractionEnabled = false
        addSubview(effectView)

        bringSubviewToFront(effectView)

        fileSizeLabel.font = UIFont.uiiransansBoldCaption2
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.textColor = Color.App.textPrimaryUIColor

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

        NSLayoutConstraint.activate([
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
            setPreloadImage()
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

        if viewModel.calMessage.rowType.isImage, state != .downloading, state != .completed && state != .thumbnailDownloaing, state != .thumbnail {
            viewModel.onTap() // Download thumbnail
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
    private func setPreloadImage() {
        guard let image = viewModel?.fileState.preloadImage else { return }
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

    public func updateProgress() {
        guard let viewModel = viewModel else { return }
        let progress = viewModel.fileState.progress
        progressView.animate(to: progress, systemIconName: viewModel.fileState.iconState)
        progressView.setProgressVisibility(visible: viewModel.fileState.state != .completed)
    }
}
