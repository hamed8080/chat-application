//
//  ThreadViewController.swift
//  Talk
//
//  Created by hamed on 12/30/23.
//

import Foundation
import UIKit
import SwiftUI
import TalkViewModels
import TalkModels
import ChatModels
import TalkUI

final class ThreadViewController: UIViewController {
    var viewModel: ThreadViewModel?
    public var tableView: UIHistoryTableView!
    private let tapGetsure = UITapGestureRecognizer()
    public lazy var sendContainer = ThreadBottomToolbar(viewModel: viewModel)
    private lazy var moveToBottom = MoveToBottomButton(viewModel: viewModel)
    private lazy var unreadMentionsButton = UnreadMenitonsButton(viewModel: viewModel)
    public private(set) lazy var topThreadToolbar = TopThreadToolbar(viewModel: viewModel)
    private var sendContainerBottomConstraint: NSLayoutConstraint?
    private var keyboardheight: CGFloat = 0
    private let emptyThreadView = EmptyThreadView()
    private var topLoading = UILoadingView()
    private var centerLoading = UILoadingView()
    private var bottomLoading = UILoadingView()
    private let vStackOverlayButtons = UIStackView()
    private lazy var dimView = DimView()
    public var contextMenuContainer: ContextMenuContainerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        registerKeyboard()
        viewModel?.delegate = self
        viewModel?.historyVM.delegate = self
        startCenterAnimation(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ThreadViewModel.threadWidth = view.frame.width
        viewModel?.historyVM.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        var hasAnyInstanceInStack = false
        navigationController?.viewControllers.forEach({ hostVC in
            hostVC.children.forEach { vc in
                if vc == self {
                    hasAnyInstanceInStack = true
                }
            }
        })
        if !hasAnyInstanceInStack, let viewModel = viewModel {
            AppState.shared.objectsContainer.navVM.cleanOnPop(threadId: viewModel.threadId)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.historyVM.setThreashold(view.bounds.height * 2.5)
        contextMenuContainer = ContextMenuContainerView(delegate: self)
        tableView.contentInset.top = topThreadToolbar.frame.height
    }

    deinit {
        print("deinit ThreadViewController")
    }
}

// MARK: Configure Views
extension ThreadViewController {
    func configureViews() {
        configureTableView()
        configureOverlayActionButtons()
        configureSendContainer()
        configureTopToolbarVStack()
        configureLoadings()
        let vStackOverlayButtonsConstraint: NSLayoutConstraint
        if Language.isRTL {
            vStackOverlayButtonsConstraint = vStackOverlayButtons.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        } else {
            vStackOverlayButtonsConstraint = vStackOverlayButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        }
        
        sendContainerBottomConstraint = sendContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        sendContainerBottomConstraint?.identifier = "sendContainerBottomConstraintThreadViewController"
        NSLayoutConstraint.activate([
            moveToBottom.widthAnchor.constraint(equalToConstant: 40),
            moveToBottom.heightAnchor.constraint(equalToConstant: 40),
            unreadMentionsButton.widthAnchor.constraint(equalToConstant: 40),
            unreadMentionsButton.heightAnchor.constraint(equalToConstant: 40),
            vStackOverlayButtonsConstraint,
            vStackOverlayButtons.bottomAnchor.constraint(equalTo: sendContainer.topAnchor, constant: -16),
            
            topThreadToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            topThreadToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topThreadToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sendContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendContainerBottomConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: topThreadToolbar.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func configureTableView() {
        tableView = UIHistoryTableView(viewModel: viewModel)
        view.addSubview(tableView)
    }
    
    private func configureTopToolbarVStack() {
        view.addSubview(topThreadToolbar)
    }
    
    private func configureSendContainer() {
        sendContainer.translatesAutoresizingMaskIntoConstraints = false
        sendContainer.accessibilityIdentifier = "sendContainerThreadViewController"
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.accessibilityIdentifier = "dimViewThreadViewController"
        dimView.viewModel = viewModel
        view.addSubview(sendContainer)
        sendContainer.onUpdateHeight = { [weak self] (height: CGFloat) in
            guard let self = self else { return }
            guard let viewModel = viewModel else { return }
            let isButtonsVisible = viewModel.sendContainerViewModel.showPickerButtons
            let safeAreaHeight = (isButtonsVisible ? 0 : view.safeAreaInsets.bottom)
            let height = (height - safeAreaHeight) + keyboardheight
            if tableView.contentInset.bottom != height {
                UIView.animate(withDuration: 0.1) { [weak self] in
                    guard let self = self else { return }
                    tableView.contentInset = .init(top: topThreadToolbar.bounds.height + 4, left: 0, bottom: height, right: 0)
                }
                if let message = viewModel.thread.lastMessageVO?.toMessage {
                    Task {
                        await viewModel.scrollVM.scrollToLastMessageIfLastMessageIsVisible(message)
                    }
                }
            }
        }
    }
    
    private func configureOverlayActionButtons() {
        vStackOverlayButtons.translatesAutoresizingMaskIntoConstraints = false
        vStackOverlayButtons.axis = .vertical
        vStackOverlayButtons.spacing = 24
        vStackOverlayButtons.alignment = .leading
        vStackOverlayButtons.accessibilityIdentifier = "vStackOverlayButtonsThreadViewController"
        moveToBottom.accessibilityIdentifier = "moveToBottomThreadViewController"
        vStackOverlayButtons.addArrangedSubview(moveToBottom)
        unreadMentionsButton.accessibilityIdentifier = "unreadMentionsButtonThreadViewController"
        vStackOverlayButtons.addArrangedSubview(unreadMentionsButton)
        view.addSubview(vStackOverlayButtons)
    }
    
    private func configureEmptyThreadView() {
        emptyThreadView.alpha = 0.0
        view.addSubview(emptyThreadView)
        emptyThreadView.translatesAutoresizingMaskIntoConstraints = false
        emptyThreadView.accessibilityIdentifier = "emptyThreadViewThreadViewController"
        NSLayoutConstraint.activate([
            emptyThreadView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyThreadView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyThreadView.topAnchor.constraint(equalTo: topThreadToolbar.bottomAnchor),
            emptyThreadView.bottomAnchor.constraint(equalTo: sendContainer.topAnchor),
        ])
    }
    
    private func configureDimView() {
        if dimView.superview == nil {
            dimView.alpha = 0.0
            view.addSubview(dimView)
            view.bringSubviewToFront(dimView)
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            dimView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            dimView.bottomAnchor.constraint(equalTo: sendContainer.topAnchor).isActive = true
        }
    }
    
    private func configureLoadings() {
        topLoading.translatesAutoresizingMaskIntoConstraints = false
        topLoading.accessibilityIdentifier = "topLoadingThreadViewController"
        tableView.addSubview(topLoading)

        centerLoading.translatesAutoresizingMaskIntoConstraints = false
        centerLoading.accessibilityIdentifier = "centerLoadingThreadViewController"

        bottomLoading.translatesAutoresizingMaskIntoConstraints = false
        bottomLoading.accessibilityIdentifier = "bottomLoadingThreadViewController"
        tableView.addSubview(bottomLoading)
        
        topLoading.animate(false)
        bottomLoading.animate(false)
        let width: CGFloat = 28
        NSLayoutConstraint.activate([
            topLoading.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -(width + 8)),
            topLoading.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            topLoading.widthAnchor.constraint(equalToConstant: width),
            topLoading.heightAnchor.constraint(equalToConstant: width),
            
            bottomLoading.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: -8),
            bottomLoading.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            bottomLoading.widthAnchor.constraint(equalToConstant: width),
            bottomLoading.heightAnchor.constraint(equalToConstant: width)
        ])
    }

    private func attachCenterLoading() {
        let width: CGFloat = 28
        view.addSubview(centerLoading)
        centerLoading.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        centerLoading.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        centerLoading.widthAnchor.constraint(equalToConstant: width).isActive = true
        centerLoading.heightAnchor.constraint(equalToConstant: width).isActive = true
    }

    private func showEmptyThread(show: Bool) {
        if show {
            configureEmptyThreadView()
            emptyThreadView.showWithAniamtion(true)
        } else {
            self.emptyThreadView.removeFromSuperViewWithAnimation()
        }
        if show {
            self.unreadMentionsButton.showWithAniamtion(false)
            self.moveToBottom.showWithAniamtion(false)
        }
    }
}

// MARK: ThreadViewDelegate
extension ThreadViewController: ThreadViewDelegate {
    func onUnreadCountChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.moveToBottom.updateUnreadCount()
        }
    }

    func onChangeUnreadMentions() {
        DispatchQueue.main.async { [weak self] in
            self?.unreadMentionsButton.onChangeUnreadMentions()
        }
    }

    func setSelection(_ value: Bool) {
        tapGetsure.isEnabled = !value
        viewModel?.selectedMessagesViewModel.setInSelectionMode(value)
        tableView.allowsMultipleSelection = value
        tableView.visibleCells.compactMap{$0 as? MessageBaseCell}.forEach { cell in
            cell.setInSelectionMode(value)
        }

        // Assure that the previous item is in select mode or not
        if let cell = prevouisVisibleIndexPath() {
            cell.setInSelectionMode(value)
        }

        // Assure that the next item is in select mode or not
        if let cell = nextVisibleIndexPath() {
            cell.setInSelectionMode(value)
        }

        showSelectionBar(value)
        // We need a delay to show selection view to calculate height of sendContainer then update to the last Message if it is visible
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.moveTolastMessageIfVisible()
        }
    }

    func updateSelectionView() {
        sendContainer.updateSelectionBar()
    }

    func lastMessageAppeared(_ appeared: Bool) {
        moveToBottom.setVisibility(visible: !appeared)
    }

    func startTopAnimation(_ animate: Bool) {
        DispatchQueue.main.async {
            self.topLoading.animate(animate)
        }
    }

    func startCenterAnimation(_ animate: Bool) {
        DispatchQueue.main.async {
            if animate {
                self.attachCenterLoading()
                self.centerLoading.animate(animate)
            } else {
                self.centerLoading.removeFromSuperViewWithAnimation()
            }
        }
    }

    func startBottomAnimation(_ animate: Bool) {
        DispatchQueue.main.async {
            self.bottomLoading.animate(animate)
        }
    }

    func openShareFiles(urls: [URL], title: String?) {
        guard let first = urls.first else { return }
        let vc = UIActivityViewController(activityItems: [LinkMetaDataManager(url: first, title: title)], applicationActivities: nil)
        present(vc, animated: true)
    }

    func onMentionListUpdated() {
        sendContainer.updateMentionList()
        tapGetsure.isEnabled = viewModel?.mentionListPickerViewModel.mentionList.count == 0
    }

    func updateAvatar(image: UIImage, participantId: Int) {
        tableView.visibleCells
            .compactMap({$0 as? PartnerMessageCell})
            .filter{$0.viewModel?.message.participant?.id == participantId}
            .forEach { cell in
                cell.setImage(image)
            }
    }

    func edited(_ indexPath: IndexPath) {
        if let cell = baseVisibleCell(indexPath) {
            cell.edited()
        }
    }

    func pinChanged(_ indexPath: IndexPath) {
        if let cell = baseVisibleCell(indexPath) {
            cell.pinChanged()
        }
    }

    func sent(_ indexPath: IndexPath) {
        if let cell = baseVisibleCell(indexPath) {
            cell.sent()
        }
    }

    func delivered(_ indexPath: IndexPath) {
        if let cell = baseVisibleCell(indexPath) {
            cell.delivered()
        }
    }

    func seen(_ indexPath: IndexPath) {
        if let cell = baseVisibleCell(indexPath) {
            cell.seen()
        }
    }

    public func updateTitleTo(_ title: String?) {
        topThreadToolbar.updateTitleTo(title)
    }

    public func updateSubtitleTo(_ subtitle: String?) {
        topThreadToolbar.updateSubtitleTo(subtitle)
    }

    public func updateImageTo(_ image: UIImage?) {
        topThreadToolbar.updateImageTo(image)
    }

    func setHighlightRowAt(_ indexPath: IndexPath, highlight: Bool) {
        if let cell = baseVisibleCell(indexPath) {
            cell.setHighlight()
        }
    }

    func showContextMenu(_ indexPath: IndexPath, contentView: UIView) {
        contextMenuContainer.setContentView(contentView, indexPath: indexPath)
        contextMenuContainer.show()
    }

    func dismissContextMenu(indexPath: IndexPath?) {
        contextMenuContainer.hide()
        if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            cell.messageContainer.resetOnDismiss()
        }
    }

    func onUpdatePinMessage() {
        topThreadToolbar.updatePinMessage()
    }
}

extension ThreadViewController: BottomToolbarDelegate {
    func showMainButtons(_ show: Bool) {
        sendContainer.showMainButtons(show)
    }

    func showSelectionBar(_ show: Bool) {
        sendContainer.showSelectionBar(show)
        showMainButtons(!show)
    }

    func showPickerButtons(_ show: Bool) {
        viewModel?.sendContainerViewModel.showPickerButtons(show)
        sendContainer.showPickerButtons(show)
        configureDimView()
        dimView.show(show)
    }
    
    func showSendButton(_ show: Bool) {
        sendContainer.showSendButton(show)
    }

    func showMicButton(_ show: Bool) {
        sendContainer.showMicButton(show)
    }

    func onItemsPicked() {
        showSendButton(true)
        showMicButton(false)
    }

    func showRecording(_ show: Bool) {
        sendContainer.openRecording(show)
    }

    func openEditMode(_ message: (any HistoryMessageProtocol)?) {
        sendContainer.openEditMode(message)
        focusOnTextView(focus: message != nil)
    }

    func openReplyMode(_ message: (any HistoryMessageProtocol)?) {
        viewModel?.replyMessage = message as? Message
        focusOnTextView(focus: message != nil)
        sendContainer.openReplyMode(message)
        scrollTo(uniqueId: message?.uniqueId ?? "", position: .middle)
    }

    func focusOnTextView(focus: Bool) {
        sendContainer.focusOnTextView(focus: focus)
    }

    func showForwardPlaceholder(show: Bool) {
        sendContainer.showForwardPlaceholder(show: show)
    }

    func showReplyPrivatelyPlaceholder(show: Bool) {
        sendContainer.showReplyPrivatelyPlaceholder(show: show)
    }
}

// MARK: Sheets Delegate
extension ThreadViewController {
    func openForwardPicker() {
        let view = SelectConversationOrContactList { [weak self] (conversation, contact) in
            self?.viewModel?.sendMessageViewModel.openDestinationConversationToForward(conversation, contact)
        }
            .environmentObject(AppState.shared.objectsContainer.threadsVM)
            .contextMenuContainer()
        //            .environmentObject(viewModel)
            .onDisappear {
                //closeSheet()
            }
        let hostVC = UIHostingController(rootView: view)
        hostVC.modalPresentationStyle = .formSheet
        present(hostVC, animated: true)
    }
}

// MARK: Scrolling to
extension ThreadViewController: HistoryScrollDelegate {
    func emptyStateChanged(isEmpty: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            showEmptyThread(show: isEmpty)
        }
    }

    func reload() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.reloadData()
        }
    }

    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition, animate: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: index, at: position, animated: animate)
        }
    }

    func scrollTo(uniqueId: String, position: UITableView.ScrollPosition, animate: Bool = true) {
        if let indexPath = viewModel?.historyVM.sections.indicesByMessageUniqueId(uniqueId) {
            scrollTo(index: indexPath, position: position, animate: animate)
        }
    }

    func reload(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [at], with: .fade)
        }
    }

    private func moveTolastMessageIfVisible() {
        if viewModel?.scrollVM.isAtBottomOfTheList == true, let indexPath = viewModel?.historyVM.sections.viewModelAndIndexPath(for: viewModel?.thread.lastMessageVO?.id)?.indexPath {
            scrollTo(index: indexPath, position: .bottom)
        }
    }

    func uploadCompleted(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.uploadCompleted(viewModel: viewModel)
        }
    }

    func downloadCompleted(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.downloadCompleted(viewModel: viewModel)
        }
    }

    func updateProgress(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.updateProgress(viewModel: viewModel)
        }
    }

    func updateThumbnail(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.updateThumbnail(viewModel: viewModel)
        }
    }

    func inserted(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.beginUpdates()
            // Insert a new section if we have a message in a new day.
            let beforeNumberOfSections = tableView.numberOfSections
            if beforeNumberOfSections < at.section + 1 { // +1 for make it count instead of index
                tableView.insertSections(IndexSet(beforeNumberOfSections..<at.section + 1), with: .none)
            }
            tableView.insertRows(at: [at], with: .fade)
            tableView.endUpdates()
        }
    }

    func inserted(_ sections: IndexSet, _ rows: [IndexPath], _ scrollTo: IndexPath?) {
        DispatchQueue.main.async { [weak self] in
            self?.inserted(sections: sections, rows: rows, scrollTo: scrollTo)
        }
    }

    private func inserted(sections: IndexSet, rows: [IndexPath], scrollTo: IndexPath?) {

        // Save the current content offset and content height
//        let beforeOffsetY = tableView.contentOffset.y
//        let beforeContentHeight = tableView.contentSize.height
//        print("before offset y is: \(beforeOffsetY)")
//
//        // Begin table view updates
//        tableView.beginUpdates()
//
//        // Insert the sections and rows without animation
//        tableView.insertSections(sections, with: .middle)
//        tableView.insertRows(at: rows, with: .middle)
//
//        // Calculate the new content size and offset
//        let afterContentHeight = tableView.contentSize.height
//        let offsetChange = afterContentHeight - beforeContentHeight
//
//        // Update the content offset to keep the visible content stationary
//        let newOffsetY = beforeOffsetY + offsetChange
//        print("new offset y is: \(newOffsetY)")
//        tableView.contentOffset.y = newOffsetY
//        tableView.setContentOffset(.init(x: 0, y: newOffsetY), animated: true)

        // End table view updates
//        tableView.endUpdates()
//
//        if let scrollTo = scrollTo {
//            self.tableView.scrollToRow(at: scrollTo, at: .top, animated: false)
//        }

        if let scrollTo = scrollTo {
            UIView.performWithoutAnimation {
                tableView.performBatchUpdates {
                    // Insert the sections and rows without animation
                    tableView.insertSections(sections, with: .top)
                    tableView.insertRows(at: rows, with: .top)
                } completion: { completed in
                    DispatchQueue.main.async {
                        self.tableView.scrollToRow(at: scrollTo, at: .top, animated: false)
                    }
                }
            }
        } else {
            tableView.performBatchUpdates {
                // Insert the sections and rows without animation
                tableView.insertSections(sections, with: .top)
                tableView.insertRows(at: rows, with: .top)
            }
        }
    }

    func inserted(at: [IndexPath]) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.insertRows(at: at, with: .fade)
            self?.tableView.endUpdates()
        }
    }

    func removed(at: IndexPath) {
        guard let viewModel = viewModel else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.beginUpdates()
            if tableView.numberOfSections > viewModel.historyVM.sections.count {
                tableView.deleteSections(IndexSet(viewModel.historyVM.sections.count..<tableView.numberOfSections), with: .fade)
            }
            tableView.deleteRows(at: [at], with: .fade)
            tableView.endUpdates()
        }
    }

    func removed(at: [IndexPath]) {
        guard let viewModel = viewModel else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.beginUpdates()
            if tableView.numberOfSections > viewModel.historyVM.sections.count {
                tableView.deleteSections(IndexSet(viewModel.historyVM.sections.count..<tableView.numberOfSections), with: .fade)
            }
            tableView.deleteRows(at: at, with: .fade)
            tableView.endUpdates()
        }
    }

    func reactionsUpdatedAt(_ indexPath: IndexPath) {
        // Delay is essential for when we get the bottom part on openning the thread for the first time to it won't lead to crash
        let wasAtBottom = viewModel?.scrollVM.isAtBottomOfTheList == true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            if let cell = self?.tableView.cellForRow(at: indexPath) as? MessageBaseCell, let viewModel = self?.viewModel?.historyVM.sections.viewModelWith(indexPath) {
                cell.reactionsUpdated(viewModel: viewModel)
                // Update geometry of table view and make cells taller
                self?.tableView?.beginUpdates()
                self?.tableView?.endUpdates()
            }
            if wasAtBottom {
                self?.viewModel?.scrollVM.scrollToBottom()
            }
        }
    }
}

struct UIKitThreadViewWrapper: UIViewControllerRepresentable {
    let threadVM: ThreadViewModel

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ThreadViewController()
        vc.viewModel = threadVM
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

// MARK: Keyboard apperance
extension ThreadViewController {
    private func registerKeyboard() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notif in
            if let rect = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                UIView.animate(withDuration: 0.2) {
                    self?.sendContainerBottomConstraint?.constant = -rect.height
                    self?.keyboardheight = rect.height
                    self?.view.layoutIfNeeded()
                } completion: { completed in
                    if completed {
                        self?.moveTolastMessageIfVisible()
                    }
                }
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.sendContainerBottomConstraint?.constant = 0
            self?.keyboardheight = 0
            UIView.animate(withDuration: 0.2) {
                self?.view.layoutIfNeeded()
            }
        }
        tapGetsure.addTarget(self, action: #selector(hideKeyboard))
        tapGetsure.isEnabled = true
        view.addGestureRecognizer(tapGetsure)
    }

    @objc private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: Table view cell helpers
extension ThreadViewController {
    private func baseVisibleCell(_ indexPath: IndexPath) -> MessageBaseCell? {
        if isVisible(indexPath), let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            return cell
        }
        return nil
    }

    private func isVisible(_ indexPath: IndexPath) -> Bool {
        tableView.indexPathsForVisibleRows?.contains(where: {$0 == indexPath}) == true
    }

    private func prevouisVisibleIndexPath() -> MessageBaseCell? {
        if let firstVisible = tableView.indexPathsForVisibleRows?.first, let previousIndexPath = viewModel?.historyVM.sections.previousIndexPath(firstVisible) {
            let cell = tableView.cellForRow(at: previousIndexPath) as? MessageBaseCell
            return cell
        }
        return nil
    }

    private func nextVisibleIndexPath() -> MessageBaseCell? {
        if let lastVisible = tableView.indexPathsForVisibleRows?.last, let nextIndexPath = viewModel?.historyVM.sections.nextIndexPath(lastVisible) {
            let cell = tableView.cellForRow(at: nextIndexPath) as? MessageBaseCell
            return cell
        }
        return nil
    }
}
