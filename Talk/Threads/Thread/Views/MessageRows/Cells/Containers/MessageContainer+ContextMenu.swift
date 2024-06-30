//
//  MessageContainerStackView+ContextMenu.swift
//  Talk
//
//  Created by hamed on 6/24/24.
//

import Foundation
import UIKit
import TalkViewModels

fileprivate struct Constants {
    static let space: CGFloat = 8
    static let margin: CGFloat = 8
    static let menuWidth: CGFloat = 256
    static let reactionWidth: CGFloat = 256
    static let reactionHeight: CGFloat = 46
    static let scaleDownOnTouch: CGFloat = 0.98
    static let scaleDownAnimationDuration = 0.2
    static let scaleUPAnimationDuration = 0.1
    static let longPressDuration = 0.3
    static let animateToRightVerticalPosition = 0.1
    static let animateToHideOriginalMessageDuration = 0.4

    struct Sizes {
        let rectInNav: CGRect
        let stackBounds: CGRect
        let originalX: CGFloat
        let navFrame: CGRect
        let minTopVertical: CGFloat
        let maxVertical: CGFloat
    }
}

extension MessageContainerStackView {
    func addMenus() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(openContextMenu))
        longGesture.minimumPressDuration = Constants.longPressDuration
        addGestureRecognizer(longGesture)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: Constants.scaleDownAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: Constants.scaleDownOnTouch, y: Constants.scaleDownOnTouch)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: Constants.scaleUPAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: Constants.scaleUPAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }

    @objc private func openContextMenu(_ sender: UIGestureRecognizer) {
        if sender.state == .began, let indexPath = indexpath(), let contentView = makeContextMenuView(indexPath) {
            delegate?.showContextMenu(indexPath, contentView: contentView)
            UIView.animate(withDuration: Constants.animateToHideOriginalMessageDuration) {
                self.alpha = 0.0
            }
        }
    }

    func makeContextMenuView(_ indexPath: IndexPath) -> UIView? {
        guard let viewModel = viewModel else { return nil }
        let vc = delegate as? ThreadViewController
        guard let vc = vc, let tableView = vc.tableView else { return nil }

        let rects = calculateRects(tableView, indexPath, vc)

        let scrollViewContainer = createScrollViewContainer(frame: rects.navFrame)

        let messageContainer = createCopyStackContainer(viewModel: viewModel, rectInNavOrigin: rects.rectInNav.origin, stackSize: rects.stackBounds.size)
        scrollViewContainer.addSubview(messageContainer)

        let reactionBarView = createReaction(viewModel, rects.originalX, messageContainer, rects.navFrame.width)
        scrollViewContainer.addSubview(reactionBarView)

        let menu = createMenu(viewModel, indexPath, messageContainer, rects.navFrame.width, rects.originalX)
        scrollViewContainer.addSubview(menu)


        animateToRightVerticalPosition(rects.minTopVertical, rects.maxVertical, rects.navFrame.height, reactionBarView, messageContainer, menu)

        return scrollViewContainer
    }

    private func calculateRects(_ tableView: UITableView, _ indexPath: IndexPath, _ vc: ThreadViewController) -> Constants.Sizes {
        let rectIntableView = tableView.rectForRow(at: indexPath)
        let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell
        let messageStack = cell?.messageContainer
        let viewInNav = vc.navigationController?.view
        let stackBounds = messageStack?.bounds ?? .zero
        let rectInContentView = messageStack?.convert(stackBounds, to: cell?.contentView) ?? .zero
        let rectInView = tableView.convert(rectIntableView, to: vc.view)
        var rectInNav = vc.navigationController?.view.convert(rectInView, to: viewInNav) ?? .zero
        rectInNav.origin.x = rectInContentView.origin.x
        let originalX = frame.origin.x
        let navFrame = viewInNav?.frame ?? .zero
        let minTopVertical = vc.topThreadToolbar.frame.height + 64
        let maxVertical = vc.sendContainer.frame.height
        return Constants.Sizes(rectInNav: rectInNav,
                               stackBounds: stackBounds,
                               originalX: originalX,
                               navFrame: navFrame,
                               minTopVertical: minTopVertical,
                               maxVertical: maxVertical
        )
    }

    private func createScrollViewContainer(frame: CGRect) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = frame
        return view
    }

    private func createCopyStackContainer(viewModel:MessageRowViewModel, rectInNavOrigin: CGPoint, stackSize: CGSize) -> MessageContainerStackView {
        let messageContainer = MessageContainerStackView(frame: .zero, isMe: viewModel.calMessage.isMe)
        messageContainer.frame = .init(origin: rectInNavOrigin, size: stackSize)
        messageContainer.set(viewModel)
        messageContainer.prepareForContextMenu(userInterfaceStyle: traitCollection.userInterfaceStyle)
        messageContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(faketapGesture)))
        return messageContainer
    }

    private func createMenu(_ viewModel: MessageRowViewModel, _ indexPath: IndexPath, _ messageContainer: MessageContainerStackView, _ vcWidth: CGFloat, _ originalX: CGFloat) -> CustomMenu {
        let menu = menu(model: .init(viewModel: viewModel), indexPath: indexPath, onMenuClickedDismiss: resetOnDismiss)
        menu.frame.origin.y = messageContainer.frame.maxY + Constants.margin

        let rightX = vcWidth - (Constants.menuWidth + Constants.margin)
        let x = messageContainer.frame.width < Constants.menuWidth ? rightX : originalX
        menu.frame.origin.x = viewModel.calMessage.isMe ? x : originalX
        menu.frame.size.width = Constants.menuWidth
        menu.frame.size.height = menu.height()
        return menu
    }

    private func createReaction(_ viewModel: MessageRowViewModel, _ originalX:CGFloat, _ messageContainer: MessageContainerStackView, _ vcWidth: CGFloat) -> UIReactionsPickerScrollView {

        let reactionsRightX = vcWidth - (Constants.reactionWidth + Constants.margin)
        let reactionsX = messageContainer.frame.width < Constants.reactionWidth ? reactionsRightX : originalX
        let reactionsView = UIReactionsPickerScrollView(size: Constants.reactionHeight)
        reactionsView.frame = .init(x: viewModel.calMessage.isMe ? reactionsX : originalX, y: messageContainer.frame.origin.y - (Constants.reactionHeight + 8), width: Constants.reactionWidth, height: Constants.reactionHeight)
        reactionsView.viewModel = viewModel
        reactionsView.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        return reactionsView
    }

    private func getRightY(_ minTopVertical: CGFloat, _ maxVertical: CGFloat, _ maxVCHeight: CGFloat, _ messageContainer: MessageContainerStackView, _ menu: CustomMenu) -> CGFloat {
        var calculatedY: CGFloat = 0
        let menuHeight = menu.height()

        if messageContainer.frame.minY < (minTopVertical - Constants.reactionHeight) {
            calculatedY = Constants.reactionHeight
        } else if messageContainer.frame.maxY > maxVCHeight - (menuHeight + Constants.space) {
            calculatedY = -((messageContainer.frame.maxY + menuHeight + maxVertical) - maxVCHeight)
        }

        return calculatedY
    }

    private func animateToRightVerticalPosition(_ minTopVertical: CGFloat, _ maxVertical: CGFloat, _ maxVCHeight: CGFloat, _ reactionView: UIReactionsPickerScrollView, _ messageContainer: MessageContainerStackView, _ menu: CustomMenu) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: Constants.animateToRightVerticalPosition) {
                let y = self.getRightY(minTopVertical, maxVertical, maxVCHeight, messageContainer, menu)
                messageContainer.frame.origin.y += y
                reactionView.frame.origin.y += y
                menu.frame.origin.y += y
            }
        }
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

    public func resetOnDismiss() {
        UIView.animate(withDuration: Constants.scaleUPAnimationDuration) {
            self.alpha = 1.0
        }
    }
}
