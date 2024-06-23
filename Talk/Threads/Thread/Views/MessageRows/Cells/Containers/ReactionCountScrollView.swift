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
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32),
            stack.widthAnchor.constraint(equalTo: widthAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if viewModel.reactionsModel.rows.isEmpty {
            reset()
            return
        }
        setIsHidden(false)
        let rows = viewModel.reactionsModel.rows
        rows.forEach { rowModel in
            let rowView = ReactionCountRowView(frame: bounds, row: rowModel, isMe: viewModel.calMessage.isMe)
            stack.addArrangedSubview(rowView)
        }
        let canShow = rows.count > 0
        setIsHidden(!canShow)
    }

    private func reset() {
        setIsHidden(true)
    }
}

final class ReactionCountRowView: UIView {
    private let reactionEmoji = UILabel()
    private let reactionCountLabel = UILabel()
    let row: ReactionRowsCalculated.Row
    let isMyMessage: Bool

    init(frame: CGRect, row: ReactionRowsCalculated.Row, isMe: Bool) {
        self.isMyMessage = isMe
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
        semanticContentAttribute = isMyMessage ? .forceRightToLeft : .forceLeftToRight

        reactionEmoji.translatesAutoresizingMaskIntoConstraints = false
        reactionEmoji.font = .systemFont(ofSize: 14)
        reactionEmoji.text = row.emoji
        addSubview(reactionEmoji)

        reactionCountLabel.translatesAutoresizingMaskIntoConstraints = false
        reactionCountLabel.font = UIFont.uiiransansBody
        reactionCountLabel.textColor = Color.App.textPrimaryUIColor
        reactionCountLabel.text = row.countText
        addSubview(reactionCountLabel)
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: 42),
            reactionEmoji.widthAnchor.constraint(equalToConstant: 20),
            reactionEmoji.heightAnchor.constraint(equalToConstant: 20),
            reactionEmoji.centerYAnchor.constraint(equalTo: centerYAnchor),
            reactionEmoji.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),

            reactionCountLabel.leadingAnchor.constraint(equalTo: reactionEmoji.trailingAnchor, constant: 4),
            reactionCountLabel.centerYAnchor.constraint(equalTo: reactionEmoji.centerYAnchor),
            reactionCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
    }
}
