//
//  ForwardMessageRow.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

final class ForwardMessageRow: UIStackView {
    private let vStack = UIStackView()
    private let forwardStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let bar = UIView()
    private var viewModel: MessageRowViewModel?

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
        forwardStaticLebel.text = "Message.forwardedFrom".localized()

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
        backgroundColor = viewModel.isMe ? Color.App.bgChatMeUIColor : Color.App.bgChatUserDarkUIColor
        semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        vStack.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        let canShow = viewModel.message.forwardInfo != nil
        forwardStaticLebel.isHidden = !canShow
        bar.isHidden = !canShow
        participantLabel.text = viewModel.message.forwardInfo?.participant?.name ?? viewModel.message.participant?.name
        participantLabel.isHidden = viewModel.message.forwardInfo?.participant?.name == nil
        isHidden = !canShow
    }

    @IBAction func onForwardTapped(_ sender: UIGestureRecognizer) {
        print("on forward tapped")
    }
}

struct ForwardMessageRowWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = ForwardMessageRow()
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ForwardMessageRow_Previews: PreviewProvider {
    struct Preview: View {
        var viewModel: MessageRowViewModel

        init(viewModel: MessageRowViewModel) {
            ThreadViewModel.maxAllowedWidth = 340
            self.viewModel = viewModel
        }

        var body: some View {
            ForwardMessageRowWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.forwardInfo != nil })!)
            .previewDisplayName("Forward")
    }
}
