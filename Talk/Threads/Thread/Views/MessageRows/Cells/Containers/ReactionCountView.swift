//
//  ReactionCountView.swift
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

final class ReactionCountView: UIScrollView {
    private let stack = UIStackView()

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
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
            stack.widthAnchor.constraint(equalTo: widthAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if viewModel.reactionsModel.rows.isEmpty {
            reset()
            return
        }
        setIsHidden(false)
//        let recitonList = viewModel.reactionsVM.reactionCountList
//        stack.subviews.forEach { reaction in
//            reaction.removeFromSuperview()
//        }
//        recitonList.forEach { reactionCount in
//            let row = ReactionCountRow(frame: bounds, reactionCount: reactionCount)
//            stack.addArrangedSubview(row)
//            row.set()
//        }
//        let canShow = recitonList.count > 0
//        isHidden = !canShow
    }

    private func reset() {
        setIsHidden(true)
    }
}

final class ReactionCountRow: UIStackView {
    private let reactionEmoji = UILabel()
    private let reactionCountLabel = UILabel()
    let reactionCount: ReactionCount
    
    init(frame: CGRect, reactionCount: ReactionCount) {
        self.reactionCount = reactionCount
        super.init(frame: frame)
        configureView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        
        reactionEmoji.translatesAutoresizingMaskIntoConstraints = false
        reactionEmoji.font = .systemFont(ofSize: 14)
        
        reactionCountLabel.font = UIFont.uiiransansBody
        reactionCountLabel.textColor = Color.App.textPrimaryUIColor
        
        axis = .horizontal
        spacing = 4
        
        addArrangedSubview(reactionEmoji)
        addArrangedSubview(reactionCountLabel)
        
        NSLayoutConstraint.activate([
            reactionEmoji.widthAnchor.constraint(equalToConstant: 20),
            reactionEmoji.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
    
    public func set() {
        if reactionCount.count ?? -1 > 0, let sticker = reactionCount.sticker {
            reactionEmoji.text = sticker.emoji
            Task {
                let countText = reactionCount.count?.localNumber(locale: Language.preferredLocale) ?? ""
                await MainActor.run {
                    reactionCountLabel.text = countText
                }
            }
        }
    }
}
