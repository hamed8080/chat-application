//
//  EditMessagePlaceholderView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import ChatModels

public final class EditMessagePlaceholderView: UIStackView {
    private let staticImageReply = UIImageView()
    private let messageImageView = UIImageView()
    private let closeButton = CloseButtonView()
    private let messageLabel = UILabel()
    private let nameLabel = UILabel()
    private let vStack = UIStackView()

    let viewModel: ThreadViewModel
    var sendVM: SendContainerViewModel { viewModel.sendContainerViewModel }

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        staticImageReply.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        nameLabel.font = UIFont.uiiransansBody
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1

        messageLabel.font = UIFont.uiiransansCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2

        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(messageLabel)

        staticImageReply.image = UIImage(systemName: "pencil")
        staticImageReply.tintColor = Color.App.accentUIColor
        staticImageReply.contentMode = .scaleAspectFit

        messageImageView.layer.cornerRadius = 4
        messageImageView.layer.masksToBounds = true
        messageImageView.contentMode = .scaleAspectFit

        addArrangedSubview(messageImageView)
        addArrangedSubview(closeButton)
        addArrangedSubview(vStack)
        addArrangedSubview(staticImageReply)

        NSLayoutConstraint.activate([
            messageImageView.widthAnchor.constraint(equalToConstant: 32),
            messageImageView.heightAnchor.constraint(equalToConstant: 32),
            staticImageReply.widthAnchor.constraint(equalToConstant: 24),
            staticImageReply.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    public func set() {
        isHidden = sendVM.editMessage == nil
        guard let editMessage = sendVM.editMessage else { return }
        let isFileType = editMessage.isFileType
        let iconName = editMessage.iconName
        let isImage = editMessage.isImage == true
        messageImageView.layer.cornerRadius = isImage ? 4 : 16
        messageLabel.text = editMessage.message ?? ""
        messageLabel.backgroundColor = isImage ? .clear : Color.App.accentUIColor

        if isImage, let image = viewModel.historyVM.messageViewModel(for: editMessage)?.image {
            messageImageView.image = image
        } else {
            messageImageView.image = nil
        }
    }

    private func close() {
        viewModel.scrollVM.disableExcessiveLoading()
        sendVM.clear()
    }

}

struct EditMessagePlaceholderView_Previews: PreviewProvider {
    struct EditMessagePlaceholderViewWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel
        func makeUIView(context: Context) -> some UIView { EditMessagePlaceholderView(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    struct Preview: View {
        var viewModel: ThreadViewModel {
            let viewModel = ThreadViewModel(thread: .init(id: 1))
            viewModel.sendContainerViewModel.editMessage = .init(threadId: 1,
                                                                 message: "Test message", messageType: .text,
                                                                 participant: .init(name: "John Doe"))
            return viewModel
        }

        var body: some View {
            EditMessagePlaceholderViewWrapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
