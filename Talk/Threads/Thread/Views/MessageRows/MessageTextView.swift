//
//  MessageTextView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import ChatModels
import TalkViewModels

//struct MessageTextView: View {
//    @EnvironmentObject var viewModel: MessageRowViewModel
//    private var message: Message { viewModel.message }
//    private var threadVM: ThreadViewModel? { viewModel.threadVM }
//
//    var body: some View {
//        // TODO: TEXT must be alignment and image must be fit
//        if !message.messageTitle.isEmpty, message.forwardInfo == nil, !viewModel.isPublicLink {
//            Text(viewModel.markdownTitle)
//                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
//                .padding(.horizontal, 6)
//                .font(.iransansBody)
//                .foregroundColor(Color.App.text)
//                .fixedSize(horizontal: false, vertical: true)
//        } else if let fileName = message.uploadFileName, message.isUnsentMessage == true {
//            Text(fileName)
//                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
//                .padding(.horizontal, 6)
//                .font(.iransansBody)
//                .foregroundColor(Color.App.text)
//        }
//    }
//}


final class MessageTextView: UIView {
    private let lblMessage = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        lblMessage.textColor = Color.App.uitext
        lblMessage.font = UIFont.uiiransansBody
        lblMessage.translatesAutoresizingMaskIntoConstraints = false
        lblMessage.numberOfLines = 0
        addSubview(lblMessage)

        NSLayoutConstraint.activate([
            lblMessage.leadingAnchor.constraint(equalTo: leadingAnchor),
            lblMessage.topAnchor.constraint(equalTo: topAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let message = viewModel.message
        lblMessage.textAlignment = viewModel.isEnglish ? .left : .right
        if !message.messageTitle.isEmpty, message.forwardInfo == nil, !viewModel.isPublicLink {
            lblMessage.attributedText = viewModel.nsMarkdownTitle
        }
    }
}

struct MessageTextViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = MessageTextView()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct MessageTextView_Previews: PreviewProvider {
    static var previews: some View {
        let message = Message(id: 1, messageType: .participantJoin, time: 155600555)
        let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        MessageTextViewWapper(viewModel: viewModel)
    }
}
