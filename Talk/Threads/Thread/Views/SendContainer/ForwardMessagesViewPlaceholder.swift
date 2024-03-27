//
//  ForwardMessagesViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels

public final class ForwardMessagePlaceholderView: UIStackView {
    private let imageReply = UIImageView()
    private let vStack = UIStackView()
    private let staticForwardLabel = UILabel()
    private let messageLabel = UILabel()
    private let viewModel: ThreadViewModel
    private let closeButton = CloseButtonView()
    private var isSingleForward: Bool {
        return AppState.shared.appStateNavigationModel.forwardMessageRequest?.messageIds.count == 1
    }

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

        staticForwardLabel.textColor = Color.App.accentUIColor
        staticForwardLabel.numberOfLines = 1
        staticForwardLabel.font = UIFont.uiiransansCaption

        messageLabel.font = UIFont.uiiransansCaption2
        messageLabel.textColor = Color.App.textPlaceholderUIColor
        messageLabel.numberOfLines = 2

        vStack.addArrangedSubview(staticForwardLabel)
        vStack.addArrangedSubview(messageLabel)

        imageReply.image = UIImage(systemName: "arrow.turn.up.right")
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
        let model = AppState.shared.appStateNavigationModel

        if isSingleForward {
            staticForwardLabel.text = "Thread.forwardTheMessage".localized()
            let message = model.forwardMessages?.first?.message ?? ""
            messageLabel.text = message
        } else {
            let localized = String(localized: .init("Thread.forwardMessages"))
            let localNumber = (model.forwardMessages?.count ?? 0).localNumber(locale: Language.preferredLocale) ?? ""
            let staticMessage = String(format: localized, localNumber)
            staticForwardLabel.text = staticMessage
            let splittedMessages = model.forwardMessages?.prefix(4).compactMap({$0.message?.prefix(20)}).joined(separator: ", ")
            messageLabel.text = splittedMessages
        }
    }

    private func close() {
        AppState.shared.appStateNavigationModel = .init()
        viewModel.selectedMessagesViewModel.clearSelection()
        viewModel.animateObjectWillChange()
    }
}

struct ForwardMessagesViewPlaceholder_Previews: PreviewProvider {

    struct ForwardMessagePlaceholderViewWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel

        func makeUIView(context: Context) -> some UIView { ForwardMessagePlaceholderView(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    struct Preview: View {
        var viewModel: ThreadViewModel {
            let viewModel = ThreadViewModel(thread: .init(id: 1))
            viewModel.forwardMessage = .init(threadId: 1,
                                           message: "Test message",
                                           messageType: .text,
                                           participant: .init(name: "John Doe"))
            return viewModel
        }

        var body: some View {
            ForwardMessagePlaceholderViewWrapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
