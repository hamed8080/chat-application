//
//  UnreadMentionsButton.swift
//  Talk
//
//  Created by hamed on 11/29/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import TalkUI

public final class UnreadMenitonsButton: UIButton {
    public weak var viewModel: ThreadViewModel?
    private let lblUnreadMentionsCount = PaddingUILabel(frame: .zero, horizontal: 4, vertical: 4)

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
        onChangeUnreadMentions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layer.backgroundColor = Color.App.bgPrimaryUIColor?.cgColor
        backgroundColor = Color.App.bgPrimaryUIColor
        layer.cornerRadius = 20
        layer.shadowRadius = 5
        layer.shadowColor = Color.App.accentUIColor?.cgColor
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
        layer.shadowOffset = .init(width: 0.0, height: 1.0)

        let lblAtSing = UILabel()
        lblAtSing.translatesAutoresizingMaskIntoConstraints = false
        lblAtSing.text = "@"
        lblAtSing.textColor = Color.App.accentUIColor
        addSubview(lblAtSing)

        lblUnreadMentionsCount.translatesAutoresizingMaskIntoConstraints = false
        lblUnreadMentionsCount.textColor = Color.App.whiteUIColor
        lblUnreadMentionsCount.font = .uiiransansBoldCaption
        lblUnreadMentionsCount.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        lblUnreadMentionsCount.layer.cornerRadius = 12
        lblUnreadMentionsCount.textAlignment = .center
        lblUnreadMentionsCount.numberOfLines = 1

        addSubview(lblUnreadMentionsCount)

        NSLayoutConstraint.activate([
            lblAtSing.centerXAnchor.constraint(equalTo: centerXAnchor),
            lblAtSing.centerYAnchor.constraint(equalTo: centerYAnchor),
            lblUnreadMentionsCount.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            lblUnreadMentionsCount.heightAnchor.constraint(equalToConstant: 24),
            lblUnreadMentionsCount.topAnchor.constraint(equalTo: topAnchor, constant: -16),
            lblUnreadMentionsCount.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    @objc private func onTap(_ sender: UIGestureRecognizer) {
        Task {
            await viewModel?.moveToFirstUnreadMessage()
        }
    }

    public func onChangeUnreadMentions() {
        guard let viewModel = viewModel?.unreadMentionsViewModel else { return }
        let hasMention = viewModel.hasMention
        setIsHidden(!hasMention)
        lblUnreadMentionsCount.text = "\(viewModel.unreadMentions.count)"
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
}
