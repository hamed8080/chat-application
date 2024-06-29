//
//  UIReactionsPickerScrollView.swift
//  Talk
//
//  Created by hamed on 6/24/24.
//

import Foundation
import UIKit
import Chat
import TalkExtensions
import TalkUI
import TalkViewModels

class UIReactionsPickerScrollView: UIView {
    private let size: CGFloat
    public weak var viewModel: MessageRowViewModel?

    init(size: CGFloat) {
        self.size = size
        super.init(frame: .zero)
        configure()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        backgroundColor = .clear
        layer.cornerRadius = size / 2
        layer.masksToBounds = true

        let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityIdentifier = "effectViewUIReactionsPickerScrollView"
        addSubview(effectView)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        effectView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        effectView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        effectView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true

        let scrollView = UIScrollView()
        effectView.accessibilityIdentifier = "scrollViewUIReactionsPickerScrollView"
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

        let hSatck = UIStackView()
        hSatck.axis = .horizontal
        hSatck.spacing = 8
        hSatck.alignment = .leading
        hSatck.distribution = .fill
        hSatck.translatesAutoresizingMaskIntoConstraints = false
        hSatck.accessibilityIdentifier = "hSatckUIReactionsPickerScrollView"
        scrollView.addSubview(hSatck)
        hSatck.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        hSatck.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        hSatck.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        hSatck.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true

        for sticker in Sticker.allCases.filter({$0 != .unknown}) {
            let button = UIImageButton(imagePadding: .init(all: 2))
            button.imageView.image = image(emoji: sticker.emoji, size: size)
            button.imageView.contentMode = .scaleAspectFit
            button.accessibilityIdentifier = "button\(sticker.id)UIReactionsPickerScrollView"
            button.action = { [weak self] in
                guard let self = self else { return }
                if let messageId = viewModel?.message.id {
                    viewModel?.threadVM?.reactionViewModel.reaction(sticker, messageId: messageId)
                    viewModel?.threadVM?.delegate?.dismissContextMenu()
                }
            }
            hSatck.addArrangedSubview(button)
        }
    }

    private func image(emoji: String, size: CGFloat) -> UIImage {
        let font = UIFont.systemFont(ofSize: size)
        let emojiSize = emoji.size(withAttributes: [.font: font])

        let renderer = UIGraphicsImageRenderer(size: emojiSize)
        let image = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(.init(origin: .zero, size: emojiSize))
            emoji.draw(at: .zero, withAttributes: [.font: font])
        }
        return image
    }
}
