//
//  CallEventCell.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import UIKit

final class CallEventCell: UITableViewCell {
    private let stack = UIStackView()
    private static let startCallImage = UIImage(systemName: "phone.arrow.up.right.fill")
    private static let endCallImage = UIImage(systemName: "phone.down.fill")
    private var statusImage = UIImageView(image: CallEventCell.startCallImage)
    private let dateLabel = UILabel()
    private let typeLabel = UILabel()
    private static let startStaticText = "Thread.callStarted".localized()
    private static let endStaticText = "Thread.callEnded".localized()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {

        stack.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        statusImage.translatesAutoresizingMaskIntoConstraints = false

        typeLabel.font = UIFont.uiiransansBody
        dateLabel.font = UIFont.uiiransansBody

        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12

        statusImage.contentMode = .scaleAspectFit

        stack.addArrangedSubview(typeLabel)
        stack.addArrangedSubview(dateLabel)
        stack.addArrangedSubview(statusImage)
        stack.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        stack.layer.cornerRadius = 14
        stack.layer.masksToBounds = true
        stack.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 32),
            statusImage.widthAnchor.constraint(equalToConstant: 18),
            statusImage.heightAnchor.constraint(equalToConstant: 18),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let message = viewModel.message
        let isStarted = message.type == .startCall
        statusImage.image = isStarted ? CallEventCell.startCallImage : CallEventCell.endCallImage
        statusImage.tintColor = isStarted ? UIColor.green : Color.App.redUIColor
        typeLabel.text = isStarted ? CallEventCell.startStaticText : CallEventCell.endStaticText
        dateLabel.text = viewModel.calMessage.callDateText
    }
}
