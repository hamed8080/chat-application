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
    private weak var viewModel: MessageRowViewModel?
    static let moreButtonId = -2

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

        let moreButton = MoreReactionButtonRow(frame: .zero, isMe: isMe)
        addArrangedSubview(moreButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        var rows = viewModel.reactionsModel.rows
        if rows.count > maxReactionsToShow {
            var arr = rows.prefix(upTo: 4)
            arr.append(.init(reactionId: FooterReactionsCountView.moreButtonId,
                              edgeInset: .zero,
                              sticker: nil,
                              emoji: "",
                              countText: "",
                              isMyReaction: false,
                              hasReaction: false,
                              selectedEmojiTabId: "General.all"))
            rows = Array(arr)
        }

        subviews.forEach { reaction in
            reaction.setIsHidden(true)
        }
        for (index ,row) in rows.enumerated() {
            if subviews.indices.contains(where: {$0 == index}), let rowView = subviews[index] as? ReactionCountRowView {
                rowView.setIsHidden(false)
                rowView.viewModel = viewModel
                rowView.setValue(row: row)
            } else if let rowView = subviews[index] as? MoreReactionButtonRow {
                rowView.setIsHidden(false)
                rowView.row = row
                rowView.viewModel = viewModel
            }
        }
    }
}
