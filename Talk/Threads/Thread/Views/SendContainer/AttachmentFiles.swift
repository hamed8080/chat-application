//
//  AttachmentFiles.swift
//  Talk
//
//  Created by hamed on 10/31/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import Additive

public final class AttachmentViewControllerContainer: UIView {
    private let viewModel: ThreadViewModel
    private var attachments: [AttachmentFile] { viewModel.attachmentsViewModel.attachments }
    private var heightConstraint: NSLayoutConstraint!

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        heightConstraint = heightAnchor.constraint(equalToConstant: 48)
        NSLayoutConstraint.activate([
            heightConstraint
        ])
    }
    
    private func setHeight() {
        if viewModel.attachmentsViewModel.isExpanded == false {
            heightConstraint.constant = 48
        } else if attachments.count > 4 {
            heightConstraint.constant = UIScreen.main.bounds.height / 3
        } else {
            heightConstraint.constant = (CGFloat(attachments.count) * 64) + 64
        }
    }

    func embed(_ parentVC: UIViewController){
        let vc = AttachmentFilesViewController()
        vc.willMove(toParent: parentVC)
        vc.view.frame = self.bounds
        parentVC.view.addSubview(vc.view)
        parentVC.addChild(vc)
        vc.didMove(toParent: parentVC)
    }
}

public final class AttachmentFileCell: UITableViewCell {
    public var viewModel: ThreadViewModel!
    public var attachment: AttachmentFile!
    private let hStack = UIStackView()
    private let imgIcon = PaddingUIImageView()
    private let lblTitle = UILabel()
    private let lblSubtitle = UILabel()
    private let btnRemove = UIButton(type: .system)

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        hStack.translatesAutoresizingMaskIntoConstraints = false
        imgIcon.translatesAutoresizingMaskIntoConstraints = false
        btnRemove.translatesAutoresizingMaskIntoConstraints = false

        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.layoutMargins = .init(horizontal: 16, vertical: 8)
        hStack.isLayoutMarginsRelativeArrangement = true

        lblTitle.font = UIFont.uiiransansBoldBody
        lblTitle.textColor = Color.App.textPrimaryUIColor

        lblSubtitle.font = UIFont.uiiransansCaption2
        lblSubtitle.textColor = Color.App.textSecondaryUIColor

        let image = UIImage(systemName: "xmark")
        btnRemove.setImage(image, for: .normal)
        btnRemove.tintColor = Color.App.textSecondaryUIColor
        btnRemove.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)

        imgIcon.layer.cornerRadius = 6
        imgIcon.layer.masksToBounds = true
        imgIcon.backgroundColor = Color.App.bgInputUIColor

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 0

        vStack.addArrangedSubview(lblTitle)
        vStack.addArrangedSubview(lblSubtitle)

        hStack.addArrangedSubview(imgIcon)
        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(btnRemove)

        contentView.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.heightAnchor.constraint(equalToConstant: 46),
            imgIcon.widthAnchor.constraint(equalToConstant: 36),
            imgIcon.heightAnchor.constraint(equalToConstant: 36),
            imgIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            btnRemove.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            btnRemove.widthAnchor.constraint(equalToConstant: 36),
            btnRemove.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    public func set(attachment: AttachmentFile) {
        lblTitle.text = attachment.title
        lblSubtitle.text = attachment.title
        let imageItem = attachment.request as? ImageItem
        let isVideo = imageItem?.isVideo == true
        let icon = attachment.icon

        if icon != nil || isVideo {
            let image = UIImage(systemName: isVideo ? "film.fill" : icon ?? "")
            imgIcon.set(image: image ?? .init(), inset: .init(all: 6))
        } else if !isVideo, let cgImage = imageItem?.data.imageScale(width: 28)?.image {
            let image = UIImage(cgImage: cgImage)
            imgIcon.set(image: image, inset: .init(all: 0))
        }
    }

    @objc private func removeTapped(_ sender: UIButton) {
        viewModel.attachmentsViewModel.remove(attachment)
        viewModel.animateObjectWillChange() /// Send button to appear
    }
}

public final class AttachmentFilesViewController: UITableViewController {
    var viewModel: ThreadViewModel?
    var attachments: [AttachmentFile] { viewModel?.attachmentsViewModel.attachments ?? [] }

    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(AttachmentFileCell.self, forCellReuseIdentifier: String(describing: AttachmentFileCell.self))
    }

    public override func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { attachments.count }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attachment = attachments[indexPath.row]
        let identifier = String(describing: AttachmentFileCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? AttachmentFileCell else { return UITableViewCell() }
        cell.viewModel = viewModel
        cell.attachment = attachment
        cell.set(attachment: attachment)
        return cell
    }
}

public final class ExpandHeaderView: UIStackView {
    private let label = UILabel()
    private let btnClear = UIButton(type: .system)
    private let imageView = UIImageView()
    private let viewModel: ThreadViewModel

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4
        layoutMargins = .init(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor
        alignment = .center

        label.font = UIFont.uiiransansBoldBody

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Color.App.textSecondaryUIColor

        btnClear.setTitle("General.cancel".localized(), for: .normal)
        btnClear.titleLabel?.font = UIFont.uiiransansCaption
        btnClear.titleLabel?.textColor = Color.App.redUIColor

        addArrangedSubview(label)
        addArrangedSubview(btnClear)
        addArrangedSubview(imageView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 36),
            imageView.widthAnchor.constraint(equalToConstant: 12),
            imageView.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    public func set() {
        let localized = String(localized: .init("Thread.sendAttachments"))
        let value = viewModel.attachmentsViewModel.attachments.count.formatted(.number)
        label.text = String(format: localized, "\(value)")
        imageView.image = UIImage(systemName: viewModel.attachmentsViewModel.isExpanded ? "chevron.down" : "chevron.up")
    }

    private func expandTapped(_ sender: UIView) {
        viewModel.attachmentsViewModel.isExpanded.toggle()
    }

    private func clearTapped(_ sender: UIButton) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)) {
            viewModel.attachmentsViewModel.clear()
            viewModel.animateObjectWillChange()
        }
    }
}

struct AttachmentFilesViewController_Previews: PreviewProvider {
    struct AttachmentFilesViewControllerWrapper: UIViewControllerRepresentable {
        let viewModel: ThreadViewModel
        func makeUIViewController(context: Context) -> some UIViewController {
            let vc = AttachmentFilesViewController()
            vc.viewModel = viewModel
            return vc
        }

        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
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
        AttachmentFilesViewControllerWrapper(viewModel: AttachmentFilesViewController_Previews.viewModel)
            .previewDisplayName("AttachmentFilesViewControllerWrapper")
    }
}
