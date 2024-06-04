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
    private var mapViewWidthConstraint: NSLayoutConstraint!
    private var mapViewHeightConstraint: NSLayoutConstraint!

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
        contentMode = .scaleAspectFill

        translatesAutoresizingMaskIntoConstraints = false

        mapViewWidthConstraint = widthAnchor.constraint(equalToConstant: 0)
        mapViewHeightConstraint = heightAnchor.constraint(equalToConstant: 0)

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onTap))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            mapViewWidthConstraint,
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
        if !viewModel.calMessage.rowType.isMap {
            reset()
            return
        }
        isHidden = false
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
            self.image = viewModel.fileState.state == .completed ? viewModel.fileState.image : DownloadFileManager.mapPlaceholder
        }
        tintColor = viewModel.fileState.state == .completed ? .clear : .gray

        if viewModel.fileState.state != .completed, viewModel.fileState.state != .downloading, viewModel.fileState.state != .thumbnailDownloaing {
            viewModel.onTap() // to download automatically image of the location
        }

        if mapViewWidthConstraint.constant != viewModel.calMessage.sizes.mapWidth {
            mapViewWidthConstraint.constant = viewModel.calMessage.sizes.mapWidth
        }

        if mapViewHeightConstraint.constant != viewModel.calMessage.sizes.mapHeight {
            mapViewHeightConstraint.constant = viewModel.calMessage.sizes.mapHeight
        }
    }

    private func reset() {
        if !isHidden {
            isHidden = true
        }

        if mapViewWidthConstraint.constant > 0 {
            mapViewWidthConstraint.constant = 0
            mapViewHeightConstraint.constant = 0
        }
    }
}
