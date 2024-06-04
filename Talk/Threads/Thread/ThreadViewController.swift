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
    weak var viewModel: ThreadViewModel?
    private var tableView: UITableView!
    private let tapGetsure = UITapGestureRecognizer()
    private lazy var sendContainer = ThreadBottomToolbar(viewModel: viewModel)
    private lazy var moveToBottom = MoveToBottomButton(viewModel: viewModel)
    private lazy var unreadMentionsButton = UnreadMenitonsButton(viewModel: viewModel)
    private lazy var topThreadToolbar = TopThreadToolbar(viewModel: viewModel)
    private var sendContainerBottomConstraint: NSLayoutConstraint?
    private var keyboardheight: CGFloat = 0
    private let emptyThreadView = EmptyThreadView()
    private var topLoading = UILoadingView()
    private var centerLoading = UILoadingView()
    private var bottomLoading = UILoadingView()
    private let vStackOverlayButtons = UIStackView()
    private lazy var dimView = DimView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        registerKeyboard()
        viewModel?.delegate = self
        viewModel?.historyVM.delegate = self
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
            AppState.shared.objectsContainer.navVM.remove(threadId: viewModel.threadId)
        }
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
        configureEmptyThreadView()
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
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: sendContainer.topAnchor),
        ])
    }

    private func configureTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 128
        tableView.estimatedSectionHeaderHeight = 32
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.prefetchDataSource = self
        tableView.allowsMultipleSelection = false // Prevent the user select things when open the thread
        tableView.allowsSelection = false // Prevent the user select things when open the thread
        tableView.sectionHeaderTopPadding = 0
        ConversationHistoryCellFactory.registerCells(tableView)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(named: "chat_bg"))
        imageView.contentMode = .scaleAspectFill
        tableView.backgroundView = imageView
        tableView.backgroundColor = Color.App.bgPrimaryUIColor
    }

    private func configureTopToolbarVStack() {
        view.addSubview(topThreadToolbar)
    }

    private func configureSendContainer() {
        sendContainer.translatesAutoresizingMaskIntoConstraints = false
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.viewModel = viewModel
        view.addSubview(sendContainer)
        view.addSubview(dimView)
        view.bringSubviewToFront(dimView)
        sendContainer.onUpdateHeight = { [weak self] (height: CGFloat) in
            guard let self = self else { return }
            guard let viewModel = viewModel else { return }
            let isButtonsVisible = viewModel.sendContainerViewModel.showActionButtons
            let safeAreaHeight = (isButtonsVisible ? 0 : view.safeAreaInsets.bottom)
            let height = (height - safeAreaHeight) + keyboardheight
            if tableView.contentInset.bottom != height {
                UIView.animate(withDuration: 0.1) { [weak self] in
                    guard let self = self else { return }
                    tableView.contentInset = .init(top: topThreadToolbar.bounds.height + 4, left: 0, bottom: height, right: 0)
                }
            }
        }
    }

    private func configureOverlayActionButtons() {
        vStackOverlayButtons.translatesAutoresizingMaskIntoConstraints = false
        vStackOverlayButtons.axis = .vertical
        vStackOverlayButtons.spacing = 24
        vStackOverlayButtons.addArrangedSubview(moveToBottom)
        vStackOverlayButtons.addArrangedSubview(unreadMentionsButton)
        view.addSubview(vStackOverlayButtons)
    }

    private func configureEmptyThreadView() {
        emptyThreadView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyThreadView)
        emptyThreadView.isHidden = true
        NSLayoutConstraint.activate([
            emptyThreadView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyThreadView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyThreadView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyThreadView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureLoadings() {
        topLoading.translatesAutoresizingMaskIntoConstraints = false
        centerLoading.translatesAutoresizingMaskIntoConstraints = false
        bottomLoading.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(topLoading)
        tableView.addSubview(centerLoading)
        tableView.addSubview(bottomLoading)

        topLoading.animate(false)
        centerLoading.animate(false)
        bottomLoading.animate(false)
        let width: CGFloat = 28
        NSLayoutConstraint.activate([
            topLoading.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -(width + 8)),
            topLoading.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            topLoading.widthAnchor.constraint(equalToConstant: width),
            topLoading.heightAnchor.constraint(equalToConstant: width),

            centerLoading.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            centerLoading.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            centerLoading.widthAnchor.constraint(equalToConstant: width),
            centerLoading.heightAnchor.constraint(equalToConstant: width),

            bottomLoading.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: -8),
            bottomLoading.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            bottomLoading.widthAnchor.constraint(equalToConstant: width),
            bottomLoading.heightAnchor.constraint(equalToConstant: width)
        ])
    }

    private func showEmptyThread(show: Bool) {
        if show {
            emptyThreadView.isHidden = true
            unreadMentionsButton.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.historyVM.setThreashold(view.bounds.height * 1.5)
    }
}

// MARK: TableView DataSource
extension ThreadViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.historyVM.sections[section].vms.count ?? 0
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.historyVM.sections.count ?? 0
    }
}

// MARK: TableView Delegate
extension ThreadViewController: UITableViewDelegate {

    @MainActor
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let viewModel = viewModel else { return nil }
        let sectionVM = viewModel.historyVM.sections[section]
        let headerView = SectionHeaderView()
        headerView.set(sectionVM)
        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        ConversationHistoryCellFactory.reuse(tableView, indexPath, viewModel)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        Task { [weak self] in
            await self?.viewModel?.historyVM.willDisplay(indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        Task { [weak self] in
            await self?.viewModel?.historyVM.didEndDisplay(indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            cell.select()
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            cell.deselect()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        makeReplyButton(indexPath: indexPath, isLeading: false)
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        makeReplyButton(indexPath: indexPath, isLeading: true)
    }
}

// MARK: Prefetch
extension ThreadViewController: UITableViewDataSourcePrefetching {
    // start potentially long-running data operations early.
    // Prefetch images and long running task before the cell appears on the screen.
    // Tip: Do all the job here on the background thread.
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {

    }

    // Cancel long running task if user scroll fast or to another position.
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {

    }
}

// MARK: ScrollView delegate
extension ThreadViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        viewModel?.historyVM.didScrollTo(scrollView.contentOffset, scrollView.contentSize)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel?.scrollVM.lastContentOffsetY = scrollView.contentOffset.y
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
        updateSelectionView()
        // We need a delay to show selection view to calculate height of sendContainer then update to the last Message if it is visible
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.moveTolastMessageIfVisible()
        }
    }

    func updateSelectionView() {
        sendContainer.selectionView.update()
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
            self.centerLoading.animate(animate)
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

    func onAttchmentButtonsMenu(show: Bool) {
        sendContainer.updateAttachmentButtonsVisibility()
        dimView.show(show)
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

    func showRecording(_ show: Bool) {
        sendContainer.openRecording(show)
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

    func relaod(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [at], with: .fade)
        }
    }

    private func moveTolastMessageIfVisible() {
        if viewModel?.scrollVM.isAtBottomOfTheList == true, let indexPath = viewModel?.historyVM.sections.viewModelAndIndexPath(for: viewModel?.thread.lastMessageVO?.id)?.indexPath {
            scrollTo(index: indexPath, position: .bottom)
        }
    }

    func reconfig(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            /// Prevent to reconfigure if the cell is not currently visible on the screen
            /// The desired cell will be dequeued and call cellForRowAtIndexPath and set valid properties if it wants to show.
            if self?.tableView.indexPathsForVisibleRows?.contains(where: {$0.row == at.row && $0.section == at.section}) == true {
                self?.tableView.reconfigureRows(at: [at])
            }
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

    func inserted(_ sections: IndexSet, _ rows: [IndexPath]) {
        DispatchQueue.main.async { [weak self] in
            self?.inserted(sections: sections, rows: rows)
        }
    }

    private func inserted(sections: IndexSet, rows: [IndexPath]) {

//        let oldContentHeight: CGFloat = tableView.contentSize.height
//        let oldOffsetY: CGFloat = tableView.contentOffset.y
//        tableView.reloadData()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            let newContentHeight: CGFloat = self.tableView.contentSize.height
//            self.tableView.contentOffset.y = oldOffsetY + (newContentHeight - oldContentHeight)
//            print("old content height: \(oldContentHeight) oldOffsetY:\(oldOffsetY) newContentHeight:\(newContentHeight) move to offset: \(oldOffsetY + (newContentHeight - oldContentHeight))")
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                print("current offsetY: \(self.tableView.contentOffset.y)")
//            }
//        }


        // Save the current content offset and content height
        let beforeOffsetY = tableView.contentOffset.y
        let beforeContentHeight = tableView.contentSize.height
        print("before offset y is: \(beforeOffsetY)")

        // Begin table view updates
        tableView.beginUpdates()

        // Insert the sections and rows without animation
        tableView.insertSections(sections, with: .none)
        tableView.insertRows(at: rows, with: .none)

        // Calculate the new content size and offset
        let afterContentHeight = tableView.contentSize.height
        let offsetChange = afterContentHeight - beforeContentHeight

        // Update the content offset to keep the visible content stationary
        let newOffsetY = beforeOffsetY + offsetChange
        print("new offset y is: \(newOffsetY)")

        // Set the new content offset
        //        tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: newOffsetY), animated: false)

        // End table view updates
        tableView.endUpdates()
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

// Reply leading/trailing button
extension ThreadViewController {
    func makeReplyButton(indexPath: IndexPath, isLeading: Bool) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }
        let sections = viewModel.historyVM.sections
        guard sections.indices.contains(indexPath.section), sections[indexPath.section].vms.indices.contains(indexPath.row) else { return nil }
        let vm = sections[indexPath.section].vms[indexPath.row]
        if isLeading && !vm.calMessage.isMe { return nil }
        if !isLeading && vm.calMessage.isMe { return nil }
        let replyAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.openReplyMode(vm.message)
            success(true)
        }
        replyAction.image = UIImage(systemName: "arrowshape.turn.up.left.circle")
        replyAction.backgroundColor = UIColor.clear.withAlphaComponent(0.001)
        let config = UISwipeActionsConfiguration(actions: [replyAction])
        return config
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
}
