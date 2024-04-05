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

final class ReplyInfoMessageRow: UIStackView {
    private let vStack = UIStackView()
    private let imageTextHStack = UIStackView()
    private let replyStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let imageIconView = ImageLoaderUIView()
    private let deletedLabel = UILabel()
    private let replyLabel = UILabel()
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
        backgroundColor = Color.App.bgSecondaryUIColor
        layer.cornerRadius = 8
        layer.masksToBounds = true

        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4

        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 0
        vStack.layoutMargins = .init(all: 4)
        vStack.isLayoutMarginsRelativeArrangement = true

        replyStaticLebel.font = UIFont.uiiransansBoldCaption2
        replyStaticLebel.textColor = Color.App.accentUIColor
        replyStaticLebel.text = "Message.replyTo".localized()

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.accentUIColor


        replyLabel.font = UIFont.uiiransansCaption3
        replyLabel.numberOfLines = 1
        replyLabel.textColor = UIColor.gray
        replyLabel.lineBreakMode = .byTruncatingTail
        replyLabel.textAlignment = .left

        imageTextHStack.axis = .horizontal
        imageTextHStack.spacing = 4

        imageTextHStack.addArrangedSubview(imageIconView)
        imageTextHStack.addArrangedSubview(replyLabel)

        deletedLabel.text = "Messages.deletedMessageReply".localized()
        deletedLabel.font = UIFont.uiiransansBoldCaption2
        deletedLabel.textColor = Color.App.redUIColor

        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 2
        hStack.addArrangedSubview(replyStaticLebel)
        hStack.addArrangedSubview(participantLabel)

        vStack.addArrangedSubview(hStack)
        vStack.addArrangedSubview(deletedLabel)
        vStack.addArrangedSubview(imageTextHStack)

        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onReplyTapped))
        addGestureRecognizer(tap)

        addArrangedSubview(bar)
        addArrangedSubview(vStack)

        NSLayoutConstraint.activate([
            imageIconView.heightAnchor.constraint(equalToConstant: 24),
            imageIconView.widthAnchor.constraint(equalToConstant: 24),
            bar.widthAnchor.constraint(equalToConstant: 1.5),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        vStack.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
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
        let canShow = viewModel.message.replyInfo != nil
        isHidden = !canShow
        imageIconView.isHidden = !hasImage
    }

    @objc func onReplyTapped(_ sender: UIGestureRecognizer) {
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
