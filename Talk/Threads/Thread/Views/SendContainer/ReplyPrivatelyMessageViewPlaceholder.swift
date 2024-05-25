//
//  ReplyPrivatelyMessageViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI

public final class ReplyPrivatelyMessagePlaceholderView: UIStackView {
    private let imageReply = UIImageView()
    private let vStack = UIStackView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let viewModel: ThreadViewModel
    private let closeButton = CloseButtonView()

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        imageReply.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .leading

        nameLabel.font = UIFont.uiiransansBody
        nameLabel.textColor = Color.App.accentUIColor
        nameLabel.numberOfLines = 1

        messageLabel.font = UIFont.uiiransansCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2

        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(messageLabel)

        imageReply.image = UIImage(systemName: "arrow.turn.up.left")
        imageReply.tintColor = Color.App.iconSecondaryUIColor

        closeButton.action = { [weak self] in
            self?.close()
        }

        addArrangedSubview(imageReply)
        addArrangedSubview(vStack)
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            imageReply.widthAnchor.constraint(equalToConstant: 24),
            imageReply.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    public func set() {
        isHidden = viewModel.replyMessage == nil
        let replyMessage = AppState.shared.appStateNavigationModel.replyPrivately
        nameLabel.text = replyMessage?.participant?.name
        nameLabel.isHidden = replyMessage?.participant?.name == nil
        Task {
            let message = replyMessage?.message ?? replyMessage?.fileMetaData?.name ?? ""
            await MainActor.run {
                messageLabel.text = message
            }
        }
    }

    private func close() {
        viewModel.scrollVM.disableExcessiveLoading()
        AppState.shared.appStateNavigationModel = .init()
//        viewModel.animateObjectWillChange()
    }
}

struct ReplyPrivatelyMessagePlaceholderView_Previews: PreviewProvider {
    struct ReplyPrivatelyMessagePlaceholderViewWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel

        func makeUIView(context: Context) -> some UIView {
            let view = ReplyMessagePlaceholderView(viewModel: viewModel)
            view.set()
            return view
        }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    struct Preview: View {
        var viewModel: ThreadViewModel {
            let viewModel = ThreadViewModel(thread: .init(id: 1))
            viewModel.replyMessage = .init(threadId: 1,
                                           message: "Test message",
                                           messageType: .text,
                                           participant: .init(name: "John Doe"))
            return viewModel
        }

        var body: some View {
            return ReplyPrivatelyMessagePlaceholderViewWrapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
