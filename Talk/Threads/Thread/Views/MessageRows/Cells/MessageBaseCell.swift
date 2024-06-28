//
//  MessageBaseCell.swift
//  Talk
//
//  Created by hamed on 6/6/24.
//

import Foundation
import TalkViewModels
import UIKit
import TalkModels
import SwiftUI

public class MessageBaseCell: UITableViewCell {
    weak var viewModel: MessageRowViewModel?
    private let container = UIView()
//    private var avatar: AvatarView?
//    private let radio = SelectMessageRadio()
    private var messageContainer: MessageContainerStackView!
    private var messageContainerBottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let isMe = self is MyselfMessageCell
        self.messageContainer = .init(frame: contentView.bounds, isMe: isMe)
        configureView(isMe: isMe)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView(isMe: Bool) {
        selectionStyle = .none // Prevent iOS selection background color view added we use direct background color on content view instead of selectedBackgroundView or backgroundView

        container.translatesAutoresizingMaskIntoConstraints = false
        container.semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        container.accessibilityIdentifier = "containerMessageBaseCell"

//        radio.translatesAutoresizingMaskIntoConstraints = false
//        radio.accessibilityIdentifier = "radioMessageBaseCell"
//        radio.setIsHidden(true)
//        container.addSubview(radio)

        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        messageContainer.accessibilityIdentifier = "messageContainerMessageBaseCell"
//        messageContainer.setContentHuggingPriority(.required, for: .horizontal)
        container.addSubview(messageContainer)

//        if self is PartnerMessageCell {
//            let avatar = AvatarView(frame: .zero)
//            self.avatar = avatar
//            self.avatar?.translatesAutoresizingMaskIntoConstraints = false
//            self.avatar?.accessibilityIdentifier = "avatarContainerMessageBaseCell"
//            container.addSubview(avatar)
//            avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4).isActive = true
//            avatar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4).isActive = true
//        }

        contentView.isUserInteractionEnabled = true
        contentView.addSubview(container)

        setConstraints()
    }

    private func setConstraints() {
        let isMe = self is MyselfMessageCell
        let isRTL = Language.isRTL
        if isRTL {
            if isMe {
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
            } else {
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
            }
        } else {
            if isMe {
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
            } else {
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
            }
        }
        messageContainerBottomConstraint = messageContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -1)
        messageContainerBottomConstraint.identifier = "messageContainerBottomConstraintMessageBaseCell"
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalTo: messageContainer.widthAnchor),
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),

            messageContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 1),
            messageContainerBottomConstraint,
            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: ThreadViewModel.maxAllowedWidth),
            messageContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
//            radio.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8)
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        messageContainer.cell = self
//        messageContainerBottomConstraint.constant = viewModel.calMessage.isLastMessageOfTheUser ? -6 : -1
//        avatar?.set(viewModel)
        messageContainer.set(viewModel)
//        radio.setIsHidden(viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == false)
//        radio.set(selected: viewModel.calMessage.state.isSelected, viewModel: viewModel)
        setSelectedBackground()
    }

    func deselect() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self, let viewModel = viewModel else { return }
            viewModel.calMessage.state.isSelected = false
//            radio.set(selected: false, viewModel: viewModel)
            setSelectedBackground()
            viewModel.threadVM?.delegate?.updateSelectionView()
        }
    }

    func select() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self, let viewModel = viewModel else { return }
            viewModel.calMessage.state.isSelected = true
//            radio.set(selected: true, viewModel: viewModel)
            setSelectedBackground()
            viewModel.threadVM?.delegate?.updateSelectionView()
        }
    }

    func setInSelectionMode(_ isInSelectionMode: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
//            radio.setIsHidden(!isInSelectionMode)
//            avatar?.updateSelectionMode()
            messageContainer.isUserInteractionEnabled = !isInSelectionMode
            if !isInSelectionMode {
                deselect()
            }
        }
    }

    private func setSelectedBackground() {
        guard let viewModel = viewModel else { return }
        if viewModel.calMessage.state.isHighlited || viewModel.calMessage.state.isSelected {
            let dark = traitCollection.userInterfaceStyle == .dark
            let selectedColor = dark ? Color.App.accentUIColor?.withAlphaComponent(0.4) : Color.App.dividerPrimaryUIColor?.withAlphaComponent(0.5)
            contentView.backgroundColor = selectedColor
        } else {
            contentView.backgroundColor = nil
        }
    }

    public func setImage(_ image: UIImage) {
//        avatar?.setImage(image: image)
    }

    public func edited() {
        messageContainer.edited()
    }

    public func pinChanged() {
        messageContainer.pinChanged()
    }

    public func sent() {
        messageContainer.sent()
    }
    
    public func delivered() {
        messageContainer.delivered()
    }

    public func seen() {
        messageContainer.seen()
    }

    public func updateProgress(viewModel: MessageRowViewModel) {
        messageContainer.updateProgress(viewModel: viewModel)
    }

    public func updateThumbnail(viewModel: MessageRowViewModel) {
        messageContainer.updateThumbnail(viewModel: viewModel)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        messageContainer.downloadCompleted(viewModel: viewModel)
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        messageContainer.uploadCompleted(viewModel: viewModel)
    }

    public func setHighlight() {
        UIView.animate(withDuration: 0.2) {
            self.setSelectedBackground()
        }
    }

    public func reactionsUpdated() {
        messageContainer.reationUpdated()
    }
}
