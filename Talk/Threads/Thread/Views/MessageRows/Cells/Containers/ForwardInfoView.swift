//
//  ForwardInfoView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

final class ForwardInfoView: UIView {
    private let forwardStaticLabel = UILabel()
    private let participantLabel = UILabel()
    private let bar = UIView()
    private weak var viewModel: MessageRowViewModel?
    private static let forwardFromStaticText = "Message.forwardedFrom".localized()

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 6
        layer.masksToBounds = true
        backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight

        forwardStaticLabel.translatesAutoresizingMaskIntoConstraints = false
        forwardStaticLabel.font = UIFont.uiiransansCaption3
        forwardStaticLabel.textColor = Color.App.accentUIColor
        forwardStaticLabel.text = ForwardInfoView.forwardFromStaticText
        forwardStaticLabel.accessibilityIdentifier = "forwardStaticLebelForwardInfoView"
        forwardStaticLabel.textAlignment = isMe ? .right : .left
        forwardStaticLabel.setContentHuggingPriority(.required, for: .vertical)
        addSubview(forwardStaticLabel)

        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.accentUIColor
        participantLabel.numberOfLines = 1
        participantLabel.accessibilityIdentifier = "participantLabelForwardInfoView"
        participantLabel.textAlignment = isMe ? .right : .left
        participantLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        addSubview(participantLabel)

        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true
        bar.accessibilityIdentifier = "barForwardInfoView"
        bar.setContentHuggingPriority(.required, for: .horizontal)
        bar.setContentCompressionResistancePriority(.required, for: .horizontal)
        bar.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        addSubview(bar)

        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onForwardTapped))
        addGestureRecognizer(tap)

        let padding: CGFloat = 6

        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 1.5),
            bar.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.5),
            
            forwardStaticLabel.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: padding),
            forwardStaticLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            forwardStaticLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),

            participantLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            participantLabel.topAnchor.constraint(equalTo: forwardStaticLabel.bottomAnchor, constant: 2),
            participantLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            participantLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        if !viewModel.calMessage.rowType.isForward {
            reset()
            return
        }
        setIsHidden(false)
        participantLabel.text = viewModel.message.forwardInfo?.participant?.name ?? viewModel.message.participant?.name
        participantLabel.setIsHidden(viewModel.message.forwardInfo?.participant?.name == nil)
    }

    @IBAction func onForwardTapped(_ sender: UIGestureRecognizer) {
        print("on forward tapped")
    }

    private func reset() {
        setIsHidden(true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
