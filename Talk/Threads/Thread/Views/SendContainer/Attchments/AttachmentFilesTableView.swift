//
//  AttachmentFilesTableView.swift
//  Talk
//
//  Created by hamed on 4/3/24.
//

import UIKit
import TalkViewModels
import TalkModels
import SwiftUI

public final class AttachmentFilesTableView: UIView {
    private let tableView = UITableView(frame: .zero, style: .plain)
    weak var viewModel: ThreadViewModel?
    var attachments: [AttachmentFile] { viewModel?.attachmentsViewModel.attachments ?? [] }
    private var heightConstraint: NSLayoutConstraint!
    private var expandViewHeightConstraint: NSLayoutConstraint!
    private let cellHeight: CGFloat = 48
    private let expandViewHeight: CGFloat = 48
    private let expandView: ExpandView

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        expandView = .init(viewModel: viewModel)
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {

        // Configure table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AttachmentFileCell.self, forCellReuseIdentifier: String(describing: AttachmentFileCell.self))
        viewModel?.attachmentsViewModel.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundView = effectView

        // Configure epxand view
        expandView.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(expandTapped))
        expandView.addGestureRecognizer(tapGesture)

        // Configure Main stack view Expand View + TablewView
        addSubview(expandView)
        addSubview(tableView)

        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        expandViewHeightConstraint = expandView.heightAnchor.constraint(equalToConstant: 48)
        NSLayoutConstraint.activate([
            heightConstraint,
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            expandView.topAnchor.constraint(equalTo: topAnchor),
            expandView.leadingAnchor.constraint(equalTo: leadingAnchor),
            expandView.trailingAnchor.constraint(equalTo: trailingAnchor),
            expandViewHeightConstraint,
            tableView.topAnchor.constraint(equalTo: expandView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setHeight() {
        if viewModel?.attachmentsViewModel.isExpanded == false {
            animateHieght(cellHeight)
        } else if attachments.count > 4 {
            animateHieght((4 * cellHeight) + expandViewHeight)
        } else if attachments.count >= 2 && attachments.count <= 4 {
            animateHieght((CGFloat(self.attachments.count) * cellHeight) + expandViewHeight)
        } else {
            // Single Attachment
            animateHieght(cellHeight)
        }
        tableView.alwaysBounceVertical = attachments.count > 4
        expandView.isHidden = attachments.count <= 1
        expandViewHeightConstraint.constant = attachments.count <= 1 ? 0 : expandViewHeight
        tableView.isHidden = viewModel?.attachmentsViewModel.isExpanded == false && attachments.count != 1
    }

    private func animateHieght(_ newValue: CGFloat) {
        self.heightConstraint.constant = newValue
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.2) {
            self.layoutIfNeeded()
        }
    }

    @objc private func expandTapped(_ sender: UIView) {
        viewModel?.attachmentsViewModel.toggleExpandMode()
    }
}

extension AttachmentFilesTableView: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        attachments.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}

extension AttachmentFilesTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attachment = attachments[indexPath.row]
        let identifier = String(describing: AttachmentFileCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? AttachmentFileCell else { return UITableViewCell() }
        cell.viewModel = viewModel
        cell.set(attachment: attachment)
        return cell
    }
}

extension AttachmentFilesTableView: AttachmentDelegate {
    public func reload() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            guard let self = self else { return }
            isHidden = viewModel?.attachmentsViewModel.attachments.isEmpty == true
            self.setHeight()
            expandView.set()
        }
    }
}
