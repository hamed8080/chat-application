//
//  ReplyMessagePlaceholderView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels

public final class ReplyMessagePlaceholderView: UIStackView {
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private weak var viewModel: ThreadViewModel?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        axis = .horizontal
        spacing = 4
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .leading

        nameLabel.font = UIFont.uiiransansBody
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1

        messageLabel.font = UIFont.uiiransansCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2

        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(messageLabel)

        let imageReply = UIImageButton(imagePadding: .init(all: 8))
        imageReply.translatesAutoresizingMaskIntoConstraints = false
        imageReply.imageView.image = UIImage(systemName: "arrow.turn.up.left")
        imageReply.tintColor = Color.App.iconSecondaryUIColor

        let closeButton = CloseButtonView()
        closeButton.action = { [weak self] in
            self?.close()
        }

        addArrangedSubview(imageReply)
        addArrangedSubview(vStack)
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            imageReply.widthAnchor.constraint(equalToConstant: 36),
            imageReply.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    public func set() {
        let replyMessage = viewModel?.replyMessage
        let showReply = replyMessage != nil
        alpha = showReply ? 0.0 : 1.0
        UIView.animate(withDuration: 0.2) {
            self.alpha = showReply ? 1.0 : 0.0
            self.isHidden = !showReply
        }

        nameLabel.text = replyMessage?.participant?.name
        nameLabel.isHidden = replyMessage?.participant?.name == nil
        Task {
            let message = replyMessage?.message ?? replyMessage?.fileMetaData?.name ?? ""
            await MainActor.run {
                messageLabel.text = message
            }
        }
    }

    private func close() {
        viewModel?.scrollVM.disableExcessiveLoading()
        viewModel?.replyMessage = nil
        viewModel?.sendContainerViewModel.setFocusOnTextView(focus: false)
        viewModel?.selectedMessagesViewModel.clearSelection()
        viewModel?.delegate?.openReplyMode(nil) // close the UI
    }
}
