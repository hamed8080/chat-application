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
import TalkModels

final class MessageTextView: UIView {
    private let textView = UITextView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false /// Only is going to be enable when we are in context menu
        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let message = viewModel.message
        textView.textAlignment = viewModel.isMe ? .right : .left
        if !message.messageTitle.isEmpty {
            textView.attributedText = viewModel.nsMarkdownTitle
        }
        textView.textColor = Color.App.textPrimaryUIColor
        textView.backgroundColor = .clear
        textView.font = UIFont.uiiransansBody

        if message.message?.contains(AppRoutes.joinLink) == true {
            let tap = MessageTapGestureRecognizer(target: self, action: #selector(onTapJoinGroup(_:)))
            tap.viewModel = viewModel
            textView.addGestureRecognizer(tap)
        }

        let canShow = message.messageTitle.isEmpty == false
        isHidden = !canShow
    }

    @objc func onTapJoinGroup(_ sender: MessageTapGestureRecognizer) {
        print("tap on group link")
    }
}

struct MessageTextViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = MessageTextView()
        view.set(viewModel)
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
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first!)
    }
}
