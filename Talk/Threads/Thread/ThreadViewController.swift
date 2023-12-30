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

final class CallEventUITableViewCell: UITableViewCell {
    var viewModel: MessageRowViewModel!

    convenience init(viewModel: MessageRowViewModel) {
        self.init(style: .default, reuseIdentifier: "CallEventUITableViewCell")
        self.viewModel = viewModel
        let label = UILabel(frame: contentView.frame)
        label.text = "call text"
        contentView.addSubview(label)
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

final class ParticipantsEventUITableViewCell: UITableViewCell {
    var viewModel: MessageRowViewModel!

    convenience init(viewModel: MessageRowViewModel) {
        self.init(style: .default, reuseIdentifier: "ParticipantsEventUITableViewCell")
        self.viewModel = viewModel
        let label = UILabel(frame: contentView.frame)
        label.attributedText = viewModel.nsMarkdownTitle
        contentView.addSubview(label)
    }
}

final class ThreadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var viewModel: ThreadViewModel!
    var tableView: UITableView!
    private var cancelable = Set<AnyCancellable> ()

    override func viewDidLoad() {
        super.viewDidLoad()
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
        return viewModel.historyVM.sections[section].messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = viewModel.historyVM.sections[indexPath.section].messages[indexPath.row]
        let identifier = cellIdentifier(for: message)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
        let viewModel = viewModel.historyVM.messageViewModel(for: message)
        let type = message.type
        switch type {
        case .endCall, .startCall:
            return CallEventUITableViewCell(viewModel: viewModel)
        case .participantJoin, .participantLeft:
            return ParticipantsEventUITableViewCell(viewModel: viewModel)
        default:
            if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                return MessageUITableViewCell(viewModel: viewModel)
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
        tableView.backgroundColor = .red
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
