//
//  MessageFooterView.swift
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

final class MessageFooterView: UIStackView {
    private let pinImage = UIImageView(image: UIImage(systemName: "pin.fill"))
    private let timelabel = UILabel()
    private let editedLabel = UILabel()
    private let statusImage = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        statusImage.translatesAutoresizingMaskIntoConstraints = false
        statusImage.translatesAutoresizingMaskIntoConstraints = false
        pinImage.translatesAutoresizingMaskIntoConstraints = false
        pinImage.translatesAutoresizingMaskIntoConstraints = false

        timelabel.font = UIFont.uiiransansCaption2
        timelabel.textColor = Color.App.textSecondaryUIColor
        editedLabel.font = UIFont.uiiransansCaption2
        editedLabel.textColor = Color.App.textSecondaryUIColor
        pinImage.tintColor = Color.App.textPrimaryUIColor

        spacing = 4
        axis = .horizontal

        addArrangedSubview(timelabel)
        addArrangedSubview(editedLabel)
        addArrangedSubview(statusImage)
        addArrangedSubview(pinImage)

        NSLayoutConstraint.activate([
            statusImage.widthAnchor.constraint(equalToConstant: 12),
            statusImage.heightAnchor.constraint(equalToConstant: 12),
            pinImage.widthAnchor.constraint(equalToConstant: 12),
            pinImage.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let message = viewModel.message
        statusImage.image = message.footerStatus.image
        statusImage.tintColor = message.uiFooterStatus.fgColor
        statusImage.isHidden = !viewModel.isMe
        timelabel.text = viewModel.timeString
        editedLabel.isHidden = !viewModel.isMe
        pinImage.isHidden = message.id != viewModel.threadVM?.thread.pinMessage?.id
    }
}

struct MessageFooterUITableViewCellWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = MessageFooterView()
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct MessageFooterWapper_Previews: PreviewProvider {
    struct Preview: View {
        @State var threadVm = ThreadViewModel(thread: .init(id: 1, pinMessage: .init(messageId: 1)))

        var body: some View {
            VStack {
                let message = Message(id: 1, messageType: .startCall, time: 155600555)
                let viewModel = MessageRowViewModel(message: message, viewModel: threadVm)
                MessageFooterUITableViewCellWapper(viewModel: viewModel)
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
