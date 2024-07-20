//
//  FooterReactionsCountView.swift
//  Talk
//
//  Created by hamed on 8/22/23.
//

import TalkExtensions
import TalkViewModels
import SwiftUI
import Chat
import TalkUI
import TalkModels

final class FooterReactionsCountView: UIStackView {
    // Sizes
    private let maxReactionsToShow: Int = 4
    private let height: CGFloat = 28
    private let margin: CGFloat = 28
    private let moreReactionButton = UIImageButton(imagePadding: .init(all: 8))
    private var viewModel: MessageRowViewModel?

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = 4
        alignment = .fill
        distribution = .fillProportionally
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        accessibilityIdentifier = "stackReactionCountScrollView"

        for _ in (0..<maxReactionsToShow) {
            let rowViewPlaceHolder = ReactionCountRowView(frame: .zero, isMe: isMe)
            addArrangedSubview(rowViewPlaceHolder)
        }

        moreReactionButton.imageView.image = UIImage(systemName: "ellipsis")
        moreReactionButton.imageView.contentMode = .scaleAspectFit
        moreReactionButton.action = { [weak self] in
            self?.openReactionDetail()
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let rows = viewModel.reactionsModel.rows
        subviews.forEach { reaction in
            reaction.setIsHidden(true)
        }
        for (index ,row) in rows.enumerated() {
            if subviews.indices.contains(where: {$0 == index}), let rowView = subviews[index] as? ReactionCountRowView {
                rowView.setIsHidden(false)
                rowView.viewModel = viewModel
                rowView.setValue(row: row)
            }
        }

        if rows.count > maxReactionsToShow, moreReactionButton.superview == nil {
            addArrangedSubview(moreReactionButton)
        } else if rows.count <= maxReactionsToShow {
            moreReactionButton.removeFromSuperview()
        }
    }

    private func openReactionDetail() {
        guard let viewModel = viewModel, let row = viewModel.reactionsModel.rows.first else { return }
        guard let vc = viewModel.threadVM?.delegate as? UIViewController else { return }
        let tabVm = ReactionTabParticipantsViewModel(messageId: viewModel.message.id ?? -1)
        tabVm.viewModel = viewModel.threadVM?.reactionViewModel

        let reatcionDetailView = MessageReactionDetailView(message: viewModel.message, row: row)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .environmentObject(tabVm)
            .frame(width: 320, height: 340)

        let hostVC = UIHostingController(rootView: reatcionDetailView)
        hostVC.view.frame = .init(x: 0, y: 0, width: 320, height: 340)
        hostVC.view.backgroundColor = .clear
        hostVC.preferredContentSize = hostVC.view.frame.size
        viewModel.threadVM?.delegate?.showContextMenu(nil, contentView: hostVC.view)
    }
}

final class ReactionCountRowView: UIView {
    // Views
    private let reactionEmojiCount = UILabel()

    // Models
    var row: ReactionRowsCalculated.Row?
    weak var viewModel: MessageRowViewModel?

    // Sizes
    private let totlaWidth: CGFloat = 42
    private let emojiWidth: CGFloat = 20
    private let margin: CGFloat = 8

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 14
        layer.masksToBounds = true
        semanticContentAttribute = isMe == true ? .forceRightToLeft : .forceLeftToRight

        reactionEmojiCount.translatesAutoresizingMaskIntoConstraints = false
        reactionEmojiCount.font = UIFont.uiiransansBody
        reactionEmojiCount.textAlignment = .center
        reactionEmojiCount.accessibilityIdentifier = "reactionEmoji"
        addSubview(reactionEmojiCount)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: totlaWidth),
            reactionEmojiCount.heightAnchor.constraint(equalToConstant: emojiWidth),
            reactionEmojiCount.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            reactionEmojiCount.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            reactionEmojiCount.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
        ])
        addContextMenu()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        addGestureRecognizer(tapGesture)
    }

    func prepareContextMenu() {
        isUserInteractionEnabled = false
    }

    func setValue(row: ReactionRowsCalculated.Row) {
        self.row = row
        reactionEmojiCount.text = "\(row.emoji) \(row.countText)"
        backgroundColor = row.isMyReaction ? Color.App.color1UIColor?.withAlphaComponent(0.9) : Color.App.accentUIColor?.withAlphaComponent(0.1)
    }

    @objc private func onTapped(_ sender: UIGestureRecognizer) {
        if let messageId = viewModel?.message.id, let sticker = row?.sticker {
            viewModel?.threadVM?.reactionViewModel.reaction(sticker, messageId: messageId)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.7
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
}

struct SwiftUIReactionCountRowWrapper: UIViewRepresentable {
    let row: ReactionRowsCalculated.Row
    let isMe: Bool

    func makeUIView(context: Context) -> some UIView {
        let view = ReactionCountRowView(frame: .zero, isMe: isMe)
        view.prepareContextMenu()
        view.setValue(row: row)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

extension ReactionCountRowView: UIContextMenuInteractionDelegate {
    private func addContextMenu() {
        let menu = UIContextMenuInteraction(delegate: self)
        addInteraction(menu)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil)  { _ in
            let closeAction = UIAction(title: "General.close".localized(), image: UIImage(systemName: "xmark.circle")) { _ in
                interaction.dismissMenu()
            }
            return UIMenu(title: "", children: [closeAction])
        }
        return config
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: any NSCopying) -> UITargetedPreview? {
        let targetedView = UIPreviewTarget(container: self, center: center)
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.shadowPath = UIBezierPath()

        guard let viewModel = self.viewModel else { return nil }
        
        let tabVm = ReactionTabParticipantsViewModel(messageId: viewModel.message.id ?? -1)
        tabVm.viewModel = viewModel.threadVM?.reactionViewModel

        let swiftUIReactionTabs = VStack(alignment: viewModel.calMessage.isMe ? .leading : .trailing) {
            if let row = row {
                SwiftUIReactionCountRowWrapper(row: row, isMe: viewModel.calMessage.isMe)
                    .frame(width: 42, height: 32)
                    .fixedSize()
                    .environment(\.colorScheme, traitCollection.userInterfaceStyle == .dark ? .dark : .light)
                    .disabled(true)
                MessageReactionDetailView(message: viewModel.message, row: row)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .environmentObject(tabVm)

        let vc = UIHostingController(rootView: swiftUIReactionTabs)
        vc.view.frame = .init(origin: .zero, size: .init(width: 300, height: 400))
        vc.view.backgroundColor = .clear
        vc.preferredContentSize = vc.view.frame.size

        return UITargetedPreview(view: vc.view, parameters: params, target: targetedView)
    }
}
