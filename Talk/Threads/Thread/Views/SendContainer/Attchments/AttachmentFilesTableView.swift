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

public final class AttachmentFilesTableView: UITableView {
    var viewModel: ThreadViewModel?
    var attachments: [AttachmentFile] { viewModel?.attachmentsViewModel.attachments ?? [] }
    private var heightConstraint: NSLayoutConstraint!
    
    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero, style: .plain)
        configureViews()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        register(AttachmentFileCell.self, forCellReuseIdentifier: String(describing: AttachmentFileCell.self))
        heightConstraint = heightAnchor.constraint(equalToConstant: 48)
        NSLayoutConstraint.activate([
            heightConstraint
        ])
    }

    private func setHeight() {
        if viewModel?.attachmentsViewModel.isExpanded == false {
            heightConstraint.constant = 48
        } else if attachments.count > 4 {
            heightConstraint.constant = UIScreen.main.bounds.height / 3
        } else {
            heightConstraint.constant = (CGFloat(attachments.count) * 64) + 64
        }
    }
}

extension AttachmentFilesTableView: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { attachments.count }
}

extension AttachmentFilesTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attachment = attachments[indexPath.row]
        let identifier = String(describing: AttachmentFileCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? AttachmentFileCell else { return UITableViewCell() }
        cell.viewModel = viewModel
        cell.attachment = attachment
        cell.set(attachment: attachment)
        return cell
    }
}

struct AttachmentFilesTableView_Previews: PreviewProvider {
    struct AttachmentFilesViewControllerWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel
        func makeUIView(context: Context) -> some UIView { AttachmentFilesTableView(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var viewModel: ThreadViewModel {
        let viewModel = ThreadViewModel(thread: .init(id: 1))
        let attachments: [AttachmentFile] = [.init(type: .file, url: .init(string: "http://www.google.com/friends")!),
                                             .init(type: .map, url: .init(string: "http://www.google.com/report")!),
                                             .init(type: .contact, url: .init(string: "http://www.google.com/music")!)]
        viewModel.attachmentsViewModel.append(attachments: attachments)
        return viewModel
    }

    static var previews: some View {
        AttachmentFilesViewControllerWrapper(viewModel: AttachmentFilesTableView_Previews.viewModel)
            .previewDisplayName("AttachmentFilesViewControllerWrapper")
    }
}
