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
    private var viewModel: MessageRowViewModel?

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
        label.layer.cornerRadius = MessageRowSizes.avatarSize / 2
        label.layer.masksToBounds = true

        backgroundColor = Color.App.color1UIColor?.withAlphaComponent(0.4)
        layer.cornerRadius = MessageRowSizes.avatarSize / 2
        layer.masksToBounds = true
        contentMode = .scaleAspectFill

        addSubview(label)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)

        widthConstraint = widthAnchor.constraint(equalToConstant: MessageRowSizes.avatarSize)
        heightConstraint = heightAnchor.constraint(equalToConstant: MessageRowSizes.avatarSize)

        NSLayoutConstraint.activate([
            widthConstraint!,
            heightConstraint!,
            label.widthAnchor.constraint(equalToConstant: MessageRowSizes.avatarSize),
            label.heightAnchor.constraint(equalToConstant: MessageRowSizes.avatarSize),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let avatarVM = viewModel.avatarImageLoader
        backgroundColor = viewModel.calculatedMessage.avatarColor
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
            widthConstraint?.constant = MessageRowSizes.avatarSize
            heightConstraint?.constant = MessageRowSizes.avatarSize
            label.text = viewModel.calculatedMessage.avatarSplitedCharaters
            if let image = avatarVM?.image {
                self.image = image
                label.isHidden = true
            } else {
                image = nil
                label.isHidden = false
            }
        } else if !viewModel.calculatedMessage.isLastMessageOfTheUser {
            backgroundColor = nil
            image = nil
            isHidden = false
            label.isHidden = true
            widthConstraint?.constant = MessageRowSizes.avatarSize
            heightConstraint?.constant = MessageRowSizes.avatarSize
        }
    }

    private func hiddenView(_ viewModel: MessageRowViewModel) -> Bool {
        let isInSelectMode = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == true
        return isInSelectMode || (viewModel.threadVM?.thread.group ?? false) == false
    }

    private func showAvatarOrUserName(_ viewModel: MessageRowViewModel) -> Bool {
        viewModel.calculatedMessage.isLastMessageOfTheUser && viewModel.calculatedMessage.isCalculated
    }

    @objc func onTap(_ sender: UIGestureRecognizer) {
        if let participant = viewModel?.message.participant {
            AppState.shared.openThread(participant: participant)
        }
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
