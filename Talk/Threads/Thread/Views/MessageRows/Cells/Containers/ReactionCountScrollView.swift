//
//  ReactionCountScrollView.swift
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

final class ReactionCountScrollView: UIScrollView {
    private let stack = UIStackView()

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        layoutMargins = .init(horizontal: 6)
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        stack.semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        stack.accessibilityIdentifier = "stackReactionCountScrollView"
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32),
            stack.widthAnchor.constraint(equalTo: widthAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let rows = viewModel.reactionsModel.rows
        if rows.isEmpty {
            setIsHidden(true)
            return
        }
        setIsHidden(false)
        stack.subviews.forEach { reaction in
            reaction.removeFromSuperview()
        }
        rows.forEach { rowModel in
            let rowView = ReactionCountRowView(frame: bounds, row: rowModel)
            rowView.viewModel = viewModel
            stack.addArrangedSubview(rowView)
        }
    }

    private func reset() {
        setIsHidden(true)
    }
}

final class ReactionCountRowView: UIView {
    private let reactionEmoji = UILabel()
    private let reactionCountLabel = UILabel()
    let row: ReactionRowsCalculated.Row
    weak var viewModel: MessageRowViewModel?
    private var centerYConstraint: NSLayoutConstraint!

    init(frame: CGRect, row: ReactionRowsCalculated.Row) {
        self.row = row
        super.init(frame: frame)
        configureView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = row.isMyReaction ? Color.App.color1UIColor?.withAlphaComponent(0.9) : Color.App.accentUIColor?.withAlphaComponent(0.1)
        layer.cornerRadius = 16
        layer.masksToBounds = true
        semanticContentAttribute = viewModel?.calMessage.isMe == true ? .forceRightToLeft : .forceLeftToRight

        reactionEmoji.translatesAutoresizingMaskIntoConstraints = false
        reactionEmoji.font = .systemFont(ofSize: 14)
        reactionEmoji.text = row.emoji
        reactionEmoji.textAlignment = .center
        reactionEmoji.accessibilityIdentifier = "reactionEmoji"
        addSubview(reactionEmoji)

        reactionCountLabel.translatesAutoresizingMaskIntoConstraints = false
        reactionCountLabel.font = UIFont.uiiransansBody
        reactionCountLabel.textColor = Color.App.textPrimaryUIColor
        reactionCountLabel.text = row.countText
        reactionCountLabel.accessibilityIdentifier = "reactionCountLabel"
        addSubview(reactionCountLabel)

        centerYConstraint = reactionEmoji.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerYConstraint.identifier = "reactionEmojicenterYConstraint"
        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: 42),
            reactionEmoji.widthAnchor.constraint(equalToConstant: 20),
            reactionEmoji.heightAnchor.constraint(equalToConstant: 20),
            centerYConstraint,
            reactionEmoji.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),

            reactionCountLabel.leadingAnchor.constraint(equalTo: reactionEmoji.trailingAnchor, constant: 4),
            reactionCountLabel.centerYAnchor.constraint(equalTo: reactionEmoji.centerYAnchor),
            reactionCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
        addContextMenu()
    }

    func prepareContextMenu() {
        centerYConstraint.constant = 16
    }
}

struct SwiftUIReactionCountRowWrapper: UIViewRepresentable {
    let row: ReactionRowsCalculated.Row
    func makeUIView(context: Context) -> some UIView {
        let view = ReactionCountRowView(frame: .zero, row: row)
        view.prepareContextMenu()
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
        
        let swiftUIReactionTabs = VStack(alignment: viewModel.calMessage.isMe ? .leading : .trailing) {
            SwiftUIReactionCountRowWrapper(row: row)
                .frame(width: 42, height: 32)
                .environment(\.colorScheme, traitCollection.userInterfaceStyle == .dark ? .dark : .light)
                .disabled(true)
            MessageReactionDetailView(message: viewModel.message, row: self.row)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .environmentObject(ReactionTabParticipantsViewModel(messageId: viewModel.message.id ?? -1))

        let vc = UIHostingController(rootView: swiftUIReactionTabs)
        vc.view.frame = .init(origin: .zero, size: .init(width: 300, height: 400))
        vc.view.backgroundColor = .clear
        vc.preferredContentSize = vc.view.frame.size

        return UITargetedPreview(view: vc.view, parameters: params, target: targetedView)
    }
}
