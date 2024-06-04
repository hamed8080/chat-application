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
    private let messageContainer = MessageContainer()
    private var message: (any HistoryMessageProtocol)? { viewModel?.message }
    private var isEmptyMessage: Bool { message?.message == nil || message?.message?.isEmpty == true  }
    private var hstackBottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView() {
        selectionStyle = .none // Prevent iOS selection background color view added we use direct background color on content view instead of selectedBackgroundView or backgroundView
        contentView.isUserInteractionEnabled = true
        hStack.translatesAutoresizingMaskIntoConstraints = false

        hStack.axis = .horizontal
        hStack.alignment = .bottom
        hStack.spacing = 8
        hStack.distribution = .fill

        radio.isHidden = true

        messageContainer.cell = self
        hStack.addArrangedSubview(radio)
        if self is PartnerMessageCell {
            let avatar = AvatarView(frame: .zero)
            hStack.addArrangedSubview(avatar)
            self.avatar = avatar
        }
        hStack.addArrangedSubview(messageContainer)

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
        hStack.semanticContentAttribute = viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight
        messageContainer.semanticContentAttribute = viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight
        hstackBottomConstraint.constant = viewModel.calMessage.isLastMessageOfTheUser ? -6 : -1
        avatar?.set(viewModel)
        messageContainer.set(viewModel)
        radio.isHidden = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == false
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
            radio.isHidden = !isInSelectionMode
            avatar?.isHidden = isInSelectionMode
            messageContainer.isUserInteractionEnabled = !isInSelectionMode
            if !isInSelectionMode {
                deselect()
            }
        }
    }

    private func setSelectedBackground() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self, let viewModel = viewModel else { return }
            if viewModel.calMessage.state.isHighlited || viewModel.calMessage.state.isSelected {
                contentView.backgroundColor = Color.App.bgChatSelectedUIColor?.withAlphaComponent(0.8)
            } else {
                contentView.backgroundColor = nil
            }
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

    public func seen() {
        messageContainer.seen()
    }
}
