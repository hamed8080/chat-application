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
    private lazy var sendContainer = ThreadBottomToolbar(viewModel: viewModel, vc: self)
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
        NSLayoutConstraint.activate([
            moveToBottom.widthAnchor.constraint(equalToConstant: 40),
            moveToBottom.heightAnchor.constraint(equalToConstant: 40),
            moveToBottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            moveToBottom.bottomAnchor.constraint(equalTo: sendContainer.topAnchor, constant: -16),
            topThreadToolbar.topAnchor.constraint(equalTo: view.topAnchor),
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
        tableView.estimatedRowHeight = 86
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.prefetchDataSource = self
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
        moveToBottom.isHidden = show
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ConversationHistoryCellFactory.height(tableView, indexPath)
    }

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

    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: index, at: position, animated: true)
        }
    }

    func scrollTo(uniqueId: String, position: UITableView.ScrollPosition) {
        let indexPath = viewModel.historyVM.indicesByMessageUniqueId(uniqueId)
        if let indexPath = indexPath {
            DispatchQueue.main.async { [weak self] in
                let indexPath = IndexPath(item: indexPath.row, section: indexPath.section)
                self?.tableView.scrollToRow(at: indexPath, at: position, animated: false)
            }
        }
    }

    func relaod(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [at], with: .fade)
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
