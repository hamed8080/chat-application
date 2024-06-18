//
//  AvatarView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import SwiftUI
import TalkViewModels

final class AvatarView: UIImageView {
    private let label = UILabel()
    private weak var viewModel: MessageRowViewModel?

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

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: MessageRowSizes.avatarSize),
            heightAnchor.constraint(equalToConstant: MessageRowSizes.avatarSize),
            label.widthAnchor.constraint(equalToConstant: MessageRowSizes.avatarSize),
            label.heightAnchor.constraint(equalToConstant: MessageRowSizes.avatarSize),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let avManager = viewModel.threadVM?.avatarManager
        backgroundColor = viewModel.calMessage.avatarColor
        label.setIsHidden(true) // reset
        label.text = viewModel.calMessage.avatarSplitedCharaters
        if hiddenView(viewModel) {
            backgroundColor = nil
            setIsHidden(true)
            image = nil
            isUserInteractionEnabled = false
        } else if viewModel.calMessage.isLastMessageOfTheUser {
            setIsHidden(false)
            if let image = avManager?.getImage(viewModel) {
                setImage(image: image)
            } else {
                image = nil
                label.isHidden = false
            }
            isUserInteractionEnabled = true
        } else if !viewModel.calMessage.isLastMessageOfTheUser {
            image = nil
            setIsHidden(false)
            backgroundColor = nil
            label.isHidden = true
            isUserInteractionEnabled = false
        }
    }

    private func hiddenView(_ viewModel: MessageRowViewModel) -> Bool {
        let isInSelectMode = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == true
        return isInSelectMode || (viewModel.threadVM?.thread.group ?? false) == false
    }

    private func showAvatarOrUserName(_ viewModel: MessageRowViewModel) -> Bool {
        viewModel.calMessage.isLastMessageOfTheUser && viewModel.calMessage.isCalculated
    }

    @objc func onTap(_ sender: UIGestureRecognizer) {
        if let participant = viewModel?.message.participant {
            AppState.shared.openThread(participant: participant)
        }
    }

    public func setImage(image: UIImage) {
        guard viewModel?.calMessage.isLastMessageOfTheUser == true else { return }
        self.image = image
        label.isHidden = true
    }
}
