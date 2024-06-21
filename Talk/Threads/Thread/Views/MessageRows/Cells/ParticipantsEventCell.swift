//
//  ParticipantsEventCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels

final class ParticipantsEventCell: UITableViewCell {
    private let label = PaddingUILabel(frame: .zero, horizontal: 32, vertical: 8)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = UIFont.uiiransansBody
        label.numberOfLines = 0
        label.textColor = Color.App.textPrimaryUIColor
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.backgroundColor = .black.withAlphaComponent(0.4)

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 1, constant: -32),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // Set content compression resistance priority
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Set content hugging priority
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    public func setValues(viewModel: MessageRowViewModel) {
        label.attributedText = viewModel.calMessage.addOrRemoveParticipantsAttr
    }
}
