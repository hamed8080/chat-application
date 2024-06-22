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
    let hStack = UIStackView()
    private var avatar: AvatarView?
    private let radio = SelectMessageRadio()
    private var messageContainer: MessageContainer!
    private var hstackBottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let isMe = self is MyselfMessageCell
        self.messageContainer = .init(frame: .zero, isMe: isMe)
        configureView(isMe: isMe)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView(isMe: Bool) {
        selectionStyle = .none // Prevent iOS selection background color view added we use direct background color on content view instead of selectedBackgroundView or backgroundView

        radio.setIsHidden(true)

        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.cell = self
        messageContainer.semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight

        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.alignment = .bottom
        hStack.spacing = 8
        hStack.distribution = .fill
        hStack.semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        if self is PartnerMessageCell {
            let avatar = AvatarView(frame: .zero)
            hStack.addArrangedSubview(avatar)
            self.avatar = avatar
        }
        hStack.addArrangedSubview(radio)
        hStack.addArrangedSubview(messageContainer)

        contentView.isUserInteractionEnabled = true
        contentView.addSubview(hStack)

        setConstraints()
    }

    private func setConstraints() {
        hstackBottomConstraint = hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: ThreadViewModel.maxAllowedWidth),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1),
            hstackBottomConstraint
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        hstackBottomConstraint.constant = viewModel.calMessage.isLastMessageOfTheUser ? -6 : -1
        avatar?.set(viewModel)
        messageContainer.set(viewModel)
        radio.setIsHidden(viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == false)
        radio.set(selected: viewModel.calMessage.state.isSelected, viewModel: viewModel)
        setSelectedBackground()
    }

    func deselect() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self, let viewModel = viewModel else { return }
            viewModel.calMessage.state.isSelected = false
            radio.set(selected: false, viewModel: viewModel)
            setSelectedBackground()
            viewModel.threadVM?.delegate?.updateSelectionView()
        }
    }

    func select() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self, let viewModel = viewModel else { return }
            viewModel.calMessage.state.isSelected = true
            radio.set(selected: true, viewModel: viewModel)
            setSelectedBackground()
            viewModel.threadVM?.delegate?.updateSelectionView()
        }
    }

    func setInSelectionMode(_ isInSelectionMode: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            radio.setIsHidden(!isInSelectionMode)
            avatar?.setIsHidden(isInSelectionMode)
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
        avatar?.setImage(image: image)
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
}
