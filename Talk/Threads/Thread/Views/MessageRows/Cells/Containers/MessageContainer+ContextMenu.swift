//
//  MessageContainerStackView+ContextMenu.swift
//  Talk
//
//  Created by hamed on 6/24/24.
//

import Foundation
import UIKit
import TalkViewModels

extension MessageContainerStackView: UIContextMenuInteractionDelegate {
    func addMenus() {
        let menu = UIContextMenuInteraction(delegate: self)
        addInteraction(menu)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self, let viewModel = viewModel else { return UIMenu() }
            return menu(model: .init(viewModel: viewModel))
        }
        return config
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: any NSCopying) -> UITargetedPreview? {


        let reactionHeight: CGFloat = 36
        let minimumReactionWidth: CGFloat = 5 * reactionHeight
        let space: CGFloat = 8

        let isMe = viewModel?.calMessage.isMe == true
        let isPartnerInGroupMessage = !isMe && viewModel?.threadVM?.thread.group == true
        let width = max(minimumReactionWidth, bounds.width)

        var center = center
        center.y -= (reactionHeight / 2) + (space / 2)
        center.x -= isPartnerInGroupMessage ? MessageRowSizes.avatarSize + 8 : 0
        let targetedView = UIPreviewTarget(container: self, center: center)
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.shadowPath = UIBezierPath()

        let messageContainer = MessageContainerStackView(frame: .zero, isMe: isMe)
        messageContainer.frame = bounds
        if let viewModel = viewModel {
            messageContainer.set(viewModel)
            messageContainer.prepareForContextMenu(userInterfaceStyle: traitCollection.userInterfaceStyle)
        }

        let container = UIStackView()
        container.backgroundColor = .clear
        container.axis = .vertical
        container.alignment = isMe ? .leading : .trailing
        container.spacing = space
        container.frame = .init(origin: .zero, size: .init(width: width, height: bounds.height + space + reactionHeight))

        let reactionsView = UIReactionsPickerScrollView(size: reactionHeight)
        reactionsView.viewModel = viewModel
        reactionsView.contextMenu = interaction
        reactionsView.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(reactionsView)
        NSLayoutConstraint.activate([
            reactionsView.heightAnchor.constraint(equalToConstant: reactionHeight),
            reactionsView.widthAnchor.constraint(equalToConstant: width),
        ])

        container.addArrangedSubview(messageContainer)

        return UITargetedPreview(view: container, parameters: params, target: targetedView)
    }
}
