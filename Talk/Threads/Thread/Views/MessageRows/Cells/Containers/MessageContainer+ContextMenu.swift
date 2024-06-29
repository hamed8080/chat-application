//
//  MessageContainerStackView+ContextMenu.swift
//  Talk
//
//  Created by hamed on 6/24/24.
//

import Foundation
import UIKit
import TalkViewModels

extension MessageContainerStackView {
    func addMenus() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = 0.3
        addGestureRecognizer(longGesture)
    }

    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        if sender.state == .began, let indexPath = indexpath(), let contentView = makeContextMenuView(indexPath) {
            delegate?.showContextMenu(indexPath, contentView: contentView)
        }
    }

    func makeContextMenuView(_ indexPath: IndexPath) -> UIView? {
        guard let viewModel = viewModel else { return nil }
        let reactionHeight: CGFloat = 46
        let minimumReactionWidth: CGFloat = 5 * reactionHeight
        let space: CGFloat = 8
        let isMe = viewModel.calMessage.isMe == true

        let vc = delegate as? ThreadViewController
        guard let vc = vc, let tableView = vc.tableView else { return nil }
        let navFrame = vc.navigationController?.view.frame ?? .zero
        let navHeight = 100

        let rectIntableView = tableView.rectForRow(at: indexPath)
        let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell
        let messageStack = cell?.messageContainer
        let stackBounds = messageStack?.bounds ?? .zero
        let rectInContentView = messageStack?.convert(stackBounds, to: cell?.contentView) ?? .zero
        let rectInView = tableView.convert(rectIntableView, to: vc.view)
        var rectInNav = vc.view.convert(rectInView, to: vc.navigationController?.view)
        rectInNav.origin.x = rectInContentView.origin.x

        let scrollViewContentView = UIView()
        scrollViewContentView.backgroundColor = .clear
        scrollViewContentView.frame = navFrame

        let messageContainer = MessageContainerStackView(frame: .zero, isMe: isMe)
        messageContainer.frame = .init(origin: rectInNav.origin, size: messageStack?.bounds.size ?? .zero)
        messageContainer.set(viewModel)
        messageContainer.prepareForContextMenu(userInterfaceStyle: traitCollection.userInterfaceStyle)
        messageContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(faketapGesture)))
        scrollViewContentView.addSubview(messageContainer)

        let margin: CGFloat = 8
        let originalX = messageContainer.frame.origin.x

        let reactionWidth: CGFloat = 256
        let reactionsRightX = navFrame.width - (reactionWidth + margin)
        let reactionsX = messageContainer.frame.width < reactionWidth ? reactionsRightX : originalX
        let reactionsView = UIReactionsPickerScrollView(size: reactionHeight)
        reactionsView.frame = .init(x: isMe ? reactionsRightX : originalX, y: messageContainer.frame.origin.y - (reactionHeight + 8), width: reactionWidth, height: reactionHeight)
        reactionsView.viewModel = viewModel
        reactionsView.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        scrollViewContentView.addSubview(reactionsView)

        let menu = menu(model: .init(viewModel: viewModel))
        menu.frame.origin.y = messageContainer.frame.maxY + 8

        let menuWidth: CGFloat = 256
        let rightX = navFrame.width - (menuWidth + margin)
        let x = messageContainer.frame.width < menuWidth ? rightX : originalX
        menu.frame.origin.x = isMe ? x : originalX
        menu.frame.size.width = menuWidth
        menu.frame.size.height = menu.height()
        scrollViewContentView.addSubview(menu)

        return scrollViewContentView
    }

    private var delegate: ThreadViewDelegate? {
        return viewModel?.threadVM?.delegate
    }

    private func indexpath() -> IndexPath? {
        guard
            let vm = viewModel,
            let indexPath = viewModel?.threadVM?.historyVM.sections.indexPath(for: vm)
        else { return nil }
        return indexPath
    }

    @objc private func faketapGesture(_ sender: UIGestureRecognizer) {
        sender.cancelsTouchesInView = true
    }
}
