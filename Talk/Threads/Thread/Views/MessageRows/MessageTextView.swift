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
        lblMessage.textColor = Color.App.textPrimaryUIColor
        lblMessage.font = UIFont.uiiransansBody
        lblMessage.numberOfLines = 0
        lblMessage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lblMessage)

        NSLayoutConstraint.activate([
            lblMessage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            lblMessage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            lblMessage.topAnchor.constraint(equalTo: topAnchor),
            lblMessage.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let message = viewModel.message
        lblMessage.textAlignment = viewModel.isEnglish ? .left : .right
        if !message.messageTitle.isEmpty, !viewModel.isPublicLink {
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

    struct Preview: View {
        @StateObject var viewModel: MessageRowViewModel

        init(viewModel: MessageRowViewModel) {
            self._viewModel = StateObject(wrappedValue: viewModel)
            Task {
                await viewModel.performaCalculation()
                await viewModel.asyncAnimateObjectWillChange()
            }
        }

        var body: some View {
            MessageTextViewWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.viewModels.first!)
    }
}
