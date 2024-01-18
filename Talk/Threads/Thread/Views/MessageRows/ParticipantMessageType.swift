//
//  ParticipantMessageType.swift
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

final class ParticipantsEventUITableViewCell: UITableViewCell {
    private let label = UILabel()
    private let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        label.font = UIFont.uiiransansBody
        label.textColor = Color.App.textPrimaryUIColor
        label.textAlignment = .center
        label.numberOfLines = 0
        container.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        container.layer.cornerRadius = 15
        container.layer.masksToBounds = true

        container.addSubview(label)
        addSubview(container)

        label.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            container.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor),
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        label.attributedText = viewModel.participantEvenMarkdown
    }
}

struct ParticipantsEventUITableViewCellWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = ParticipantsEventUITableViewCell()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ParticipantsEventUITableViewCellWapper_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let message = Message(id: 1, messageType: .participantJoin, time: 155600555)
            let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
            ParticipantsEventUITableViewCellWapper(viewModel: viewModel)
        }
    }
}
