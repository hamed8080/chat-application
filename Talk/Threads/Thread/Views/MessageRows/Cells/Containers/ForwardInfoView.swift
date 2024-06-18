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

final class ForwardInfoView: UIStackView {
    private let vStack = UIStackView()
    private let forwardStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let bar = UIView()
    private weak var viewModel: MessageRowViewModel?
    private static let forwardFromStaticText = "Message.forwardedFrom".localized()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 6
        layer.masksToBounds = true

        bar.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4

        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 0
        vStack.layoutMargins = .init(horizontal: 4, vertical: 8)
        vStack.isLayoutMarginsRelativeArrangement = true

        forwardStaticLebel.font = UIFont.uiiransansCaption3
        forwardStaticLebel.textColor = Color.App.accentUIColor
        forwardStaticLebel.text = ForwardInfoView.forwardFromStaticText

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.accentUIColor
        participantLabel.numberOfLines = 1

        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        vStack.addArrangedSubview(forwardStaticLebel)
        vStack.addArrangedSubview(participantLabel)

        addArrangedSubview(bar)
        addArrangedSubview(vStack)

        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onForwardTapped))
        addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 1.5),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        if !viewModel.calMessage.rowType.isForward {
            reset()
            return
        }
        setIsHidden(false)
        backgroundColor = viewModel.calMessage.isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        setSemanticContent(viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight)
        vStack.setSemanticContent(viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight)
        participantLabel.text = viewModel.message.forwardInfo?.participant?.name ?? viewModel.message.participant?.name
        participantLabel.setIsHidden(viewModel.message.forwardInfo?.participant?.name == nil)
    }

    @IBAction func onForwardTapped(_ sender: UIGestureRecognizer) {
        print("on forward tapped")
    }

    private func reset() {
        setIsHidden(true)
    }
}
