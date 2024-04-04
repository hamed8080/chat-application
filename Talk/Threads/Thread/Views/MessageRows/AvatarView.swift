//
//  AvatarView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

final class AvatarView: UIImageView {
    private let label = UILabel()
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = true
        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = UIFont.uiiransansCaption
        label.textColor = Color.App.whiteUIColor
        label.textAlignment = .center
        label.backgroundColor = Color.App.color1UIColor?.withAlphaComponent(0.4)
        label.layer.cornerRadius = MessageRowViewModel.avatarSize / 2
        label.layer.masksToBounds = true

        backgroundColor = Color.App.color1UIColor?.withAlphaComponent(0.4)
        layer.cornerRadius = MessageRowViewModel.avatarSize / 2
        layer.masksToBounds = true
        contentMode = .scaleAspectFill

        addSubview(label)

        widthConstraint = widthAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize)
        heightConstraint = heightAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize)

        NSLayoutConstraint.activate([
            widthConstraint!,
            heightConstraint!,
            label.widthAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize),
            label.heightAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let avatarVM = viewModel.avatarImageLoader
        backgroundColor = viewModel.avatarColor
        avatarVM?.onImage = { [weak self] image in
            self?.image = image
            self?.label.isHidden = true
        }
        if avatarVM?.isImageReady == false {
            Task {
                await avatarVM?.fetch()
            }
        }
        if hiddenView(viewModel) {
            backgroundColor = nil
            isHidden = true
        } else if showAvatarOrUserName(viewModel) {
            isHidden = false
            widthConstraint?.constant = MessageRowViewModel.avatarSize
            heightConstraint?.constant = MessageRowViewModel.avatarSize
            label.text = viewModel.avatarSplitedCharaters
            if let image = avatarVM?.image {
                self.image = image
                label.isHidden = true
            } else {
                image = nil
                label.isHidden = false
            }
        } else if isSameUser(viewModel) {
            backgroundColor = nil
            image = nil
            isHidden = false
            label.isHidden = true
            widthConstraint?.constant = MessageRowViewModel.avatarSize
            heightConstraint?.constant = MessageRowViewModel.avatarSize
        }
    }

    private func hiddenView(_ viewModel: MessageRowViewModel) -> Bool {
        let isInSelectMode = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == true
        return isInSelectMode || (viewModel.threadVM?.thread.group ?? false) == false || viewModel.isMe
    }

    private func showAvatarOrUserName(_ viewModel: MessageRowViewModel) -> Bool {
        !viewModel.isMe && viewModel.isLastMessageOfTheUser && viewModel.isCalculated
    }

    private func isSameUser(_ viewModel: MessageRowViewModel) -> Bool {
        !viewModel.isMe && !viewModel.isLastMessageOfTheUser
    }
}

struct AvatarViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = AvatarView(frame: .zero)
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}
