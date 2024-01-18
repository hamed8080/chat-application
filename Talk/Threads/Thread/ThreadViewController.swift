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

final class MessageUITableViewCell: UITableViewCell {
    let textView = UITextView()
    var viewModel: MessageRowViewModel!

    convenience init(viewModel: MessageRowViewModel) {
        self.init(style: .default, reuseIdentifier: "MessageUITableViewCell")
        self.viewModel = viewModel
        textView.attributedText = viewModel.nsMarkdownTitle
        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)
//        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
}

final class UnreadBubbleUITableViewCell: UITableViewCell {

    convenience init(viewModel: MessageRowViewModel) {
        self.init(style: .default, reuseIdentifier: "UnreadBubbleUITableViewCell")
        let label = UILabel(frame: contentView.frame)
        label.text = "unread bubble"
        contentView.addSubview(label)
    }
}

final class ThreadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var viewModel: ThreadViewModel!
    var tableView: UITableView!
    private var cancelable = Set<AnyCancellable> ()

    override func viewDidLoad() {
        super.viewDidLoad()
        ThreadViewModel.threadWidth = view.frame.width
        configureViews()
        setupObservers()
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = viewModel.historyVM.sections[indexPath.section].vms[indexPath.row].message
        let identifier = cellIdentifier(for: message)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
        guard let viewModel = viewModel.historyVM.messageViewModel(for: message) else { return UITableViewCell() }
        let type = message.type
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
            if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                let cell = (cell as? TextMessageTypeCell) ?? TextMessageTypeCell(viewModel: viewModel)
                cell.setValues(viewModel: viewModel)
                return cell
            } else if message is UnreadMessageProtocol {
                return UnreadBubbleUITableViewCell()
            } else {
                return UITableViewCell()
            }
        }
    }

    enum CellTypes: String {
        case call = "CallEventUITableViewCell"
        case message = "MessageUITableViewCell"
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

    func reload() {
        tableView.reloadData()
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
        tableView.register(MessageUITableViewCell.self, forCellReuseIdentifier: "MessageUITableViewCell")
        tableView.register(CallEventUITableViewCell.self, forCellReuseIdentifier: "CallEventUITableViewCell")
        tableView.register(ParticipantsEventUITableViewCell.self, forCellReuseIdentifier: "ParticipantsEventUITableViewCell")
        tableView.register(UnreadBubbleUITableViewCell.self, forCellReuseIdentifier: "UnreadBubbleUITableViewCell")
        view.addSubview(tableView)
    }

    private func setupObservers() {
        viewModel.historyVM.objectWillChange
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancelable)
    }
}
