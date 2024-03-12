//
//  UnsentMessageView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import ChatModels

final class UnsentMessageView: UIView {
    private let stack = UIStackView()
    private let btnCancel = UIButton()
    private let btnResend = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        btnCancel.setTitle("General.cancel".localized(), for: .normal)
        btnResend.setTitle("Messages.resend".localized(), for: .normal)
        stack.axis = .horizontal
        stack.spacing = 16
        stack.layoutMargins = UIEdgeInsets(horizontal: 6)

        stack.addArrangedSubview(btnResend)
        stack.addArrangedSubview(btnCancel)

        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        
    }
}

struct UnsentMessageViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        return UnsentMessageView()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct UnsentMessageView_Previews: PreviewProvider {
    static var previews: some View {
        let message = Message(id: 1, messageType: .participantJoin, time: 155600555)
        let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        UnsentMessageViewWapper(viewModel: viewModel)
    }
}
