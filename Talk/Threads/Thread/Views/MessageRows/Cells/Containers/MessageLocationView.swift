//
//  MessageLocationView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import Chat

final class MessageLocationView: UIImageView {
    private weak var viewModel: MessageRowViewModel?
    private var mapViewHeightConstraint: NSLayoutConstraint!

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
        contentMode = .scaleAspectFill

        mapViewHeightConstraint = heightAnchor.constraint(equalToConstant: 0)
        mapViewHeightConstraint.identifier = "mapViewHeightConstraintMessageLocationView"

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onTap))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: 340),
            mapViewHeightConstraint
        ])
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        let message = viewModel?.message
        if let url = message?.neshanURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
            if let fileURL = viewModel.calMessage.fileURL {
                self.setImage(fileURL: fileURL)
            } else {
                self.image = viewModel.fileState.preloadImage ?? DownloadFileManager.mapPlaceholder
            }
        }
        tintColor = viewModel.fileState.state == .completed ? .clear : .gray

        if canDownloadAutomatically(viewModel) {
            viewModel.onTap() // to download automatically image of the location
        }

        if mapViewHeightConstraint.constant != viewModel.calMessage.sizes.mapHeight {
            mapViewHeightConstraint.constant = viewModel.calMessage.sizes.mapHeight
        }
    }

    private func canDownloadAutomatically(_ viewModel: MessageRowViewModel) -> Bool {
        let state = viewModel.fileState.state
        let canDownload = state != .undefined && state != .completed && state != .downloading && state != .thumbnailDownloaing
        return canDownload
    }

    private func setImage(fileURL: URL?) {
        Task { @HistoryActor in
            if let scaledImage = fileURL?.imageScale(width: 300)?.image {
                await MainActor.run {
                    self.image = UIImage(cgImage: scaledImage)
                }
            } 
        }
    }
}
