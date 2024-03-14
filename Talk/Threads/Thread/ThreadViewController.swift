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
import Combine
import TalkModels
import ChatModels

final class ThreadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var viewModel: ThreadViewModel!
    var tableView: UITableView!
    private var cancelable = Set<AnyCancellable> ()

    override func viewDidLoad() {
        super.viewDidLoad()
        ThreadViewModel.threadWidth = view.frame.width
        configureViews()
        viewModel.historyVM.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.historyVM.startFetchingHistory()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.historyVM.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.historyVM.sections[section].vms.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionVM = viewModel.historyVM.sections[section]
        let headerView = SectionHeaderView()
        headerView.set(sectionVM)
        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = viewModel.historyVM.sections[indexPath.section].vms[indexPath.row].message
        let identifier = cellIdentifier(for: message)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
        guard let viewModel = viewModel.historyVM.messageViewModel(for: message) else { return UITableViewCell() }
        let type = message.type
//        Task {
//            await self.viewModel.historyVM.onMessageAppear(viewModel.message)
//        }
        switch type {
        case .endCall, .startCall:
            let cell = (cell as? CallEventUITableViewCell) ?? CallEventUITableViewCell()
            cell.setValues(viewModel: viewModel)
            return cell
        case .participantJoin, .participantLeft:
            let cell = (cell as? ParticipantsEventUITableViewCell) ?? ParticipantsEventUITableViewCell()
            cell.setValues(viewModel: viewModel)
            return cell
        default:
            if let cell = cell as? TextMessageTypeCell, message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                cell.setValues(viewModel: viewModel)
                return cell
            } else if message is UnreadMessageProtocol {
                return UnreadBubbleUITableViewCell()
            } else {
                return UITableViewCell()
            }
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }

    enum CellTypes: String {
        case call = "CallEventUITableViewCell"
        case message = "TextMessageTypeCell"
        case participants = "ParticipantsEventUITableViewCell"
        case bubble = "UnreadBubbleUITableViewCell"
        case unknown
    }

    private func cellIdentifier(for message: Message) -> CellTypes {
        let type = message.type
        switch type {
        case .endCall, .startCall:
            return .call
        case .participantJoin, .participantLeft:
            return .participants
        default:
            if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                return .message
            } else if message is UnreadMessageProtocol {
                return .bubble
            } else {
                return .unknown
            }
        }
    }
}

extension ThreadViewController {
    func configureViews() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(TextMessageTypeCell.self, forCellReuseIdentifier: "TextMessageTypeCell")
        tableView.register(CallEventUITableViewCell.self, forCellReuseIdentifier: "CallEventUITableViewCell")
        tableView.register(ParticipantsEventUITableViewCell.self, forCellReuseIdentifier: "ParticipantsEventUITableViewCell")
        tableView.register(UnreadBubbleUITableViewCell.self, forCellReuseIdentifier: "UnreadBubbleUITableViewCell")
        view.addSubview(tableView)

        let imageView = UIImageView(image: UIImage(named: "chat_bg"))
        view.backgroundColor = Color.App.bgPrimaryUIColor
        view.addSubview(imageView)

        view.bringSubviewToFront(tableView)
    }
}

// MARK: Scrolling to
extension ThreadViewController: HistoryScrollDelegate {
    func reload() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func scrollTo(index: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: index, at: .bottom, animated: true)
        }
    }

    func scrollTo(uniqueId: String) {
        let index = viewModel.historyVM.indicesByMessageUniqueId(uniqueId)
        if let row = index?.messageIndex, let section = index?.sectionIndex {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.scrollToRow(at: IndexPath(item: row, section: section), at: .bottom, animated: true)
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
    
    func insertd(at: [IndexPath]) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.insertRows(at: at, with: .fade)
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
