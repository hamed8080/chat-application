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

final class MessageTextView: UITextView {
    private var viewModel: MessageRowViewModel?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        isScrollEnabled = false
        isEditable = false
        isSelectable = false /// Only is going to be enable when we are in context menu
        ///
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapJoinGroup(_:)))
        addGestureRecognizer(tap)
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let message = viewModel.message
        if !message.messageTitle.isEmpty {
            attributedText = viewModel.nsMarkdownTitle
        }
        textAlignment = viewModel.isMe || !viewModel.isEnglish ? .right : .left
        textColor = Color.App.textPrimaryUIColor
        backgroundColor = .clear
        font = UIFont.uiiransansBody
        isUserInteractionEnabled = viewModel.rowType.isPublicLink
        let canShow = message.messageTitle.isEmpty == false && !viewModel.rowType.isPublicLink
        isHidden = !canShow
    }

    @objc func onTapJoinGroup(_ sender: UIGestureRecognizer) {
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
