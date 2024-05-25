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

final class ThreadViewController: UIViewController {
    var viewModel: ThreadViewModel!
    private var tableView: UITableView!
    private lazy var sendContainer = ThreadBottomToolbar(viewModel: viewModel)
    private lazy var moveToBottom = MoveToBottomButton(viewModel: viewModel)
    private lazy var unreadMentionsButton = UnreadMenitonsButton(viewModel: viewModel)
    private lazy var topThreadToolbar = TopThreadToolbar(viewModel: viewModel)
    private let emptyThreadView = EmptyThreadView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        viewModel.delegate = self
        viewModel.historyVM.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ThreadViewModel.threadWidth = view.frame.width
        viewModel.historyVM.start()
        configureNavigationBar()
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
        if !hasAnyInstanceInStack {
            AppState.shared.objectsContainer.navVM.remove(threadId: viewModel.threadId)
        }
    }
}

// MARK: Configure Views
extension ThreadViewController {
    func configureViews() {
        configureTableView()
        configureMoveToBottom()
        configureUnreadMentionsButton()
        configureEmptyThreadView()
        configureSendContainer()
        configureTopToolbarVStack()
        let moveToBottomHorizontalConstraint: NSLayoutConstraint
        if Language.isRTL {
            moveToBottomHorizontalConstraint = moveToBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        } else {
            moveToBottomHorizontalConstraint = moveToBottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        }
        NSLayoutConstraint.activate([
            moveToBottom.widthAnchor.constraint(equalToConstant: 40),
            moveToBottom.heightAnchor.constraint(equalToConstant: 40),
            moveToBottom.bottomAnchor.constraint(equalTo: sendContainer.topAnchor, constant: -16),
            moveToBottomHorizontalConstraint,
            topThreadToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topThreadToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topThreadToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sendContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: topThreadToolbar.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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

    private func configureNavigationBar() {
        navigationItem.title = viewModel.thread.computedTitle
    }

    private func configureSendContainer() {
        sendContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendContainer)
        sendContainer.onUpdateHeight = { [weak self] height in
            self?.tableView.contentInset = .init(top: 0, left: 0, bottom: height, right: 0)
        }
    }

    private func configureMoveToBottom() {
        view.addSubview(moveToBottom)
        moveToBottom.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureUnreadMentionsButton() {
        view.addSubview(unreadMentionsButton)
        unreadMentionsButton.translatesAutoresizingMaskIntoConstraints = false
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

    private func showEmptyThread(show: Bool) {
        emptyThreadView.isHidden = !show
        unreadMentionsButton.isHidden = show
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.historyVM.threshold = (view.window?.windowScene?.screen.bounds.size.height ?? 0) * 3.5
        configureNavigationBar()
    }
}

// MARK: TableView DataSource
extension ThreadViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.historyVM.sections[section].vms.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.historyVM.sections.count
    }
}

// MARK: TableView Delegate
extension ThreadViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
        viewModel.historyVM.willDisplay(indexPath)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.historyVM.didEndDisplay(indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? TextMessageBaseCellType {
            cell.select()
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? TextMessageBaseCellType {
            cell.deselect()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let replyAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, _ in
            guard let self = self else { return }
            let section = viewModel.historyVM.sections[indexPath.section]
            if section.vms.indices.contains(indexPath.row) {
                let message = section.vms[indexPath.row].message
                viewModel.replyMessage = message
                viewModel.sendContainerViewModel.setFocusOnTextView(focus: true)
            }
        }
        replyAction.image = UIImage(systemName: "arrowshape.turn.up.left.circle")
        replyAction.backgroundColor = UIColor.clear.withAlphaComponent(0.001)
        let config = UISwipeActionsConfiguration(actions: [replyAction])
        return config
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
        viewModel.historyVM.didScrollTo(scrollView.contentOffset, scrollView.contentSize)
    }
}

// MARK: ThreadViewDelegate
extension ThreadViewController: ThreadViewDelegate {
    func onUnreadCountChanged() {
        moveToBottom.updateUnreadCount()
    }

    func onChangeUnreadMentions() {
        unreadMentionsButton.onChangeUnreadMentions()
    }

    func setSelection(_ value: Bool) {
        viewModel.selectedMessagesViewModel.setInSelectionMode(value)
        tableView.allowsMultipleSelection = value
        tableView.visibleCells.compactMap{$0 as? TextMessageBaseCellType}.forEach { cell in
            cell.setInSelectionMode(value)
        }
    }

    func updateCount() {
        sendContainer.selectionView.updateCount()
    }

    func lastMessageAppeared(_ appeared: Bool) {
        moveToBottom.setVisibility(visible: !appeared)
    }

    func openForwardPicker() {
//        let view = SelectConversationOrContactList { [weak self] (conversation, contact) in
//            self?.viewModel.sendMessageViewModel.openDestinationConversationToForward(conversation, contact)
//        }
//        .environmentObject(AppState.shared.objectsContainer.threadsVM)
//        .contextMenuContainer()
//        .environmentObject(viewModel)
//        .onDisappear {
//            //closeSheet()
//        }
//        let hostVC = UIHostingController(rootView: view)
//        hostVC.modalPresentationStyle = .formSheet
//        present(hostVC, animated: true)
    }

    func startTopAnimation(_ animate: Bool) {

    }

    func startCenterAnimation(_ animate: Bool) {

    }

    func startBottomAnimation(_ animate: Bool) {

    }
}

// MARK: Scrolling to
extension ThreadViewController: HistoryScrollDelegate {
    func reload() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.reloadData()
            showEmptyThread(show: viewModel.historyVM.isEmptyThread)
        }
    }

    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition, animate: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: index, at: position, animated: animate)
        }
    }

    func scrollTo(uniqueId: String, position: UITableView.ScrollPosition, animate: Bool = true) {
        if let indexPath = viewModel.historyVM.indicesByMessageUniqueId(uniqueId) {
            scrollTo(index: indexPath, position: position, animate: animate)
        }
    }

    func relaod(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [at], with: .fade)
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

    func insertd(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.insertRows(at: [at], with: .fade)
        }
    }

    func inserted(_ sections: IndexSet, _ rows: [IndexPath]) {
        DispatchQueue.main.async { [weak self] in
            self?.inserted(sections: sections, rows: rows)
        }
    }

    private func inserted(sections: IndexSet, rows: [IndexPath]) {
        let beforeOffsetY = tableView.contentOffset.y
        let beforeContentHeight = tableView.contentSize.height
        print("before offxet y is:\(beforeOffsetY)")
        tableView.beginUpdates()

        tableView.insertSections(sections, with: .none)
        tableView.insertRows(at: rows, with: .none)

        let afterContentSize = self.tableView.contentSize
        let afterContentOffset = self.tableView.contentOffset
        let newOffsetY = abs(afterContentOffset.y + (afterContentSize.height - beforeContentHeight))
        print("after offxet y is:\(afterContentOffset.y)")
        print("new offxet y is:\(newOffsetY)")
        tableView.setContentOffset(.init(x: afterContentOffset.x, y: newOffsetY), animated: false)

        tableView.endUpdates()
    }

    func insertd(at: [IndexPath]) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.insertRows(at: at, with: .fade)
            self?.tableView.endUpdates()
        }
    }

    func remove(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.deleteRows(at: [at], with: .fade)
        }
    }

    func remove(at: [IndexPath]) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.deleteRows(at: at, with: .fade)
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
