//
//  ReplyInfoMessageRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import Additive

final class ReplyInfoMessageRow: UIButton {
    private let replyStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let imageIconView = ImageLoaderUIView()
    private let deletedLabel = UILabel()
    private let replyLabel = UILabel()
    private let bar = UIView()
    private var heightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        configuration = .borderless()

        translatesAutoresizingMaskIntoConstraints = false
        replyStaticLebel.translatesAutoresizingMaskIntoConstraints = false
        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        deletedLabel.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false

        replyStaticLebel.font = UIFont.uiiransansCaption3
        replyStaticLebel.textColor = Color.App.textPrimaryUIColor
        replyStaticLebel.text = "Message.replyTo".localized()

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.textPrimaryUIColor

        replyLabel.font = UIFont.uiiransansCaption3
        replyLabel.numberOfLines = 2
        replyLabel.textColor = UIColor.gray
        replyLabel.lineBreakMode = .byTruncatingTail
        replyLabel.textAlignment = .left

        deletedLabel.text = "Messages.deletedMessageReply".localized()
        deletedLabel.font = UIFont.uiiransansBoldCaption2
        deletedLabel.textColor = Color.App.redUIColor

        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        addSubview(replyStaticLebel)
        addSubview(participantLabel)
        addSubview(imageIconView)
        addSubview(deletedLabel)
        addSubview(replyLabel)
        addSubview(bar)
        heightConstraint = heightAnchor.constraint(equalToConstant: 52)
        NSLayoutConstraint.activate([
            heightConstraint,
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.widthAnchor.constraint(equalToConstant: 1.5),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor),
            replyStaticLebel.topAnchor.constraint(equalTo: topAnchor),
            replyStaticLebel.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
            participantLabel.topAnchor.constraint(equalTo: replyStaticLebel.bottomAnchor, constant: 2),
            participantLabel.leadingAnchor.constraint(equalTo: replyStaticLebel.leadingAnchor),
            replyLabel.topAnchor.constraint(equalTo: participantLabel.bottomAnchor, constant: 2),
            imageIconView.leadingAnchor.constraint(equalTo: replyStaticLebel.leadingAnchor),
            replyLabel.leadingAnchor.constraint(equalTo: imageIconView.trailingAnchor, constant: 8),
            replyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let replyInfo = viewModel.message.replyInfo
        participantLabel.text = viewModel.message.replyInfo?.participant?.name
        participantLabel.isHidden = viewModel.message.replyInfo?.participant?.name == nil
        replyLabel.text = replyInfo?.message
        replyLabel.isHidden = replyInfo?.message?.isEmpty == true
        replyLabel.textAlignment = viewModel.isEnglish || viewModel.isMe ? .right : .left
        deletedLabel.isHidden = replyInfo?.deleted == nil || replyInfo?.deleted == false
        let hasImage = viewModel.isReplyImage
        imageIconView.isHidden = !hasImage
        if viewModel.isReplyImage, let url = viewModel.replyLink {
            imageIconView.setValues(config: .init(url: url, metaData: viewModel.message.replyInfo?.metadata))
        }
        registerGestures(viewModel)
        let canShow = viewModel.message.replyInfo != nil
        isHidden = !canShow
        heightConstraint.constant = canShow ? 52 : 0
        imageIconView.widthAnchor.constraint(equalToConstant: hasImage ? 24 : 0).isActive = true
    }

    private func registerGestures(_ viewModel: MessageRowViewModel) {
        isUserInteractionEnabled = true
        let tap = MessageTapGestureRecognizer(target: self, action: #selector(onReplyTapped(_:)))
        tap.viewModel = viewModel
        addGestureRecognizer(tap)
    }

    @objc func onReplyTapped(_ sender: MessageTapGestureRecognizer) {
        print("on reply tapped")
    }
}

struct ReplyInfoMessageRowWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = ReplyInfoMessageRow()
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ReplyInfoMessageRow_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel: MessageRowViewModel

        init(viewModel: MessageRowViewModel) {
            ThreadViewModel.maxAllowedWidth = 340
            self._viewModel = StateObject(wrappedValue: viewModel)
            Task {
                await viewModel.performaCalculation()
                await viewModel.asyncAnimateObjectWillChange()
            }
        }

        var body: some View {
            ReplyInfoMessageRowWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.replyInfo != nil })!)
    }
}
