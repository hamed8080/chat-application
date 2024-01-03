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

//struct ForwardMessageRow: View {
//    @EnvironmentObject var viewModel: MessageRowViewModel
//    var message: Message? { viewModel.message }
//
//    var body: some View {
//        if let forwardInfo = message?.forwardInfo, let forwardThread = forwardInfo.conversation {
//            Button {
//                AppState.shared.objectsContainer.navVM.append(thread: forwardThread)
//            } label: {
//                HStack(spacing: 8) {
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Message.forwardedFrom")
//                            .foregroundStyle(Color.App.primary)
//                            .font(.iransansCaption3)
//                        /// When we are the sender of forward we use forwardInfo.participant.name unless we use message.participant.name because it's nil
//                        if let name = forwardInfo.participant?.name ?? message?.participant?.name {
//                            Text(name)
//                                .font(.iransansBoldBody)
//                                .foregroundStyle(Color.App.primary)
//                        }
//                        if message?.message != nil {
//                            Text(viewModel.markdownTitle)
//                                .multilineTextAlignment(.leading)
//                                .padding(.horizontal, 6)
//                                .font(.iransansBody)
//                                .foregroundColor(Color.App.text)
//                                .fixedSize(horizontal: false, vertical: true)
//                        }
//                    }
//                }
//                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: viewModel.isMe ? 4 : 8))
//                .overlay(alignment: .leading) {
//                    RoundedRectangle(cornerRadius: 3)
//                        .stroke(lineWidth: 1.5)
//                        .fill(Color.App.primary)
//                        .frame(maxWidth: 1.5)
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
//            .buttonStyle(.borderless)
//            .truncationMode(.tail)
//            .contentShape(Rectangle())
//            .padding(EdgeInsets(top: 6, leading: viewModel.isMe ? 6 : 0, bottom: 6, trailing: viewModel.isMe ? 0 : 6))
//            .background(Color.App.bgInput.opacity(0.5))
//            .clipShape(RoundedRectangle(cornerRadius: 6))
//        }
//    }
//}


final class ForwardMessageRow: UIButton {
    private let stack = UIStackView()
    private let hStack = UIStackView()
    private let forwardStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let imageIconView = UIImageView()
    private let forwardLabel = UILabel()
    private let bar = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.uibgInput?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        configuration = .borderless()

        forwardStaticLebel.font = UIFont.uiiransansCaption3
        forwardStaticLebel.textColor = Color.App.uiprimary
        forwardStaticLebel.text = "Message.forwardedFrom".localized()

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.uiprimary
        participantLabel.text = "Message.replyTo".localized()

        forwardLabel.font = UIFont.uiiransansCaption3
        forwardLabel.numberOfLines = 0
        forwardLabel.textColor = Color.App.uitext
        forwardLabel.lineBreakMode = .byTruncatingTail

        bar.backgroundColor = Color.App.uiprimary
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.layoutMargins = UIEdgeInsets(all: 8)
        stack.isLayoutMarginsRelativeArrangement = true

        hStack.axis = .horizontal
        hStack.spacing = 4

        hStack.addArrangedSubview(bar)
        hStack.addArrangedSubview(imageIconView)
        hStack.addArrangedSubview(forwardLabel)

        stack.addArrangedSubview(forwardStaticLebel)
        stack.addArrangedSubview(participantLabel)
        stack.addArrangedSubview(hStack)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 1.5),
            bar.heightAnchor.constraint(equalToConstant: 48),
            imageIconView.widthAnchor.constraint(equalToConstant: 28),
            imageIconView.heightAnchor.constraint(equalToConstant: 28),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stack.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let replyInfo = viewModel.message.replyInfo
        participantLabel.text = viewModel.message.replyInfo?.participant?.name
        participantLabel.isHidden = viewModel.message.replyInfo?.participant?.name == nil
        forwardLabel.attributedText = viewModel.nsMarkdownTitle
        forwardLabel.isHidden = replyInfo?.message?.isEmpty == true
        forwardLabel.textAlignment = viewModel.isEnglish || viewModel.isMe ? .right : .left
    }
}

struct ForwardMessageRowWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = ForwardMessageRow()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ForwardMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        let message = Message(id: 1, messageType: .participantJoin, time: 155600555)
        let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        ForwardMessageRowWapper(viewModel: viewModel)
    }
}
