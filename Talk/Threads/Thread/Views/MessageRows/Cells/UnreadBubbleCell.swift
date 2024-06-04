//
//  UnreadBubbleCell.swift
//  Talk
//
//  Created by hamed on 7/6/23.
//

import SwiftUI
import ChatModels
import TalkViewModels

final class UnreadBubbleCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = true
        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = UIFont.uiiransansCaption
        label.textColor = Color.App.textPrimaryUIColor
        label.textAlignment = .center
        label.text = "Messages.unreadMessages".localized()
        label.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
        ])
    }
}

struct UnreadMessagesBubbleWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        return UnreadBubbleCell()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct UnreadMessagesBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let message = Message(id: 1, messageType: .participantJoin, time: 155600555)
            let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
            UnreadMessagesBubbleWapper(viewModel: viewModel)
        }
    }
}
