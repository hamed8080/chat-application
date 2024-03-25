//
//  ThreadPinMessageView.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import Chat
import ChatDTO
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

public final class ThreadPinMessageView: UIStackView, ThreadPinMessageViewModelDelegate {
    private let bar = UIView()
    private let pinImageView = UIImageView(frame: .zero)
    private let imageView = UIImageView(frame: .zero)
    private let textButton = UIButton(type: .system)
    private let unpinButton = UIButton(type: .system)
    private let viewModel: ThreadPinMessageViewModel!

    public init(viewModel: ThreadPinMessageViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
        viewModel.delegate = self
        Task {
            viewModel.downloadImageThumbnail()
            await viewModel.calculate()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textButton.translatesAutoresizingMaskIntoConstraints = false
        unpinButton.translatesAutoresizingMaskIntoConstraints = false

        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2

        pinImageView.image = UIImage(systemName: "pin.fill")
        pinImageView.contentMode = .scaleAspectFit
        pinImageView.tintColor = Color.App.accentUIColor

        textButton.titleLabel?.font = UIFont.uiiransansBody
        textButton.titleLabel?.numberOfLines = 1
        textButton.contentHorizontalAlignment = .left
        textButton.setTitleColor(Color.App.textPrimaryUIColor, for: .normal)
        textButton.setTitleColor(Color.App.textPrimaryUIColor?.withAlphaComponent(0.5), for: .highlighted)
        textButton.addTarget(self, action: #selector(onPinMessageTapped), for: .touchUpInside)

        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .green

        let image = UIImage(systemName: "xmark")
        unpinButton.setImage(image, for: .normal)
        unpinButton.imageView?.contentMode = .scaleAspectFit
        unpinButton.tintColor = Color.App.iconSecondaryUIColor
        unpinButton.addTarget(self, action: #selector(onUnpinMessageTapped), for: .touchUpInside)

        axis = .horizontal
        spacing = 8
        alignment = .center
        layoutMargins = .init(horizontal: 8)
        isLayoutMarginsRelativeArrangement = true

        addArrangedSubview(bar)
        addArrangedSubview(pinImageView)
        addArrangedSubview(imageView)
        addArrangedSubview(textButton)
        addArrangedSubview(unpinButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),
            bar.widthAnchor.constraint(equalToConstant: 3),
            bar.heightAnchor.constraint(equalToConstant: 24),
            pinImageView.widthAnchor.constraint(equalToConstant: 10),
            pinImageView.heightAnchor.constraint(equalToConstant: 10),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
            unpinButton.widthAnchor.constraint(equalToConstant: 24),
            unpinButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    public func onUpdate() {
        set()
    }

    @objc func onPinMessageTapped(_ sender: UIButton) {
        viewModel.moveToPinnedMessage()
    }

    @objc func onUnpinMessageTapped(_ sender: UIGestureRecognizer) {
        viewModel.unpinMessage(viewModel.message?.messageId ?? -1)
    }

    func set() {
        if let image = viewModel.image {
            imageView.image = image
            imageView.layer.cornerRadius = 4
        } else if let icon = viewModel.icon {
            let image = UIImage(systemName: icon)
            imageView.image = image
            imageView.tintColor = Color.App.textSecondaryUIColor
            imageView.layer.cornerRadius = 0
        } else {
            imageView.isHidden = true
        }
        unpinButton.isHidden = !viewModel.canUnpinMessage
        textButton.setTitle(viewModel.title, for: .normal)
        isHidden = !viewModel.hasPinMessage
    }
}

struct ThreadPinMessageViewWrapper: UIViewRepresentable {


    func makeUIView(context: Context) -> some UIView {
        let viewModel = ThreadPinMessageViewModel(thread: .init(id: 1, pinMessage: .init(messageId: 1, text: "Hello", time: 2313244564, timeNanos: nil, sender: nil, metaData: nil, systemMetadata: nil, notifyAll: nil)))
        let view = ThreadPinMessageView(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ThreadPinMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadPinMessageViewWrapper()
    }
}
