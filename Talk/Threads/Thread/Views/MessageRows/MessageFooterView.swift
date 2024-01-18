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

struct MessageFooterView: View {
    var message: Message { viewModel.message }
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        HStack {
            Text(viewModel.timeString)
                .foregroundColor(Color.App.textPrimary.opacity(0.5))
                .font(.iransansCaption2)

            if message.edited == true {
                Text("Messages.Footer.edited")
                    .foregroundColor(Color.App.textSecondary)
                    .font(.iransansCaption2)
            }

            if viewModel.isMe {
                Image(uiImage: message.footerStatus.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundColor(message.footerStatus.fgColor)
            }

            if message.id == viewModel.threadVM?.thread.pinMessage?.id {
                Image(systemName: "pin.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundColor(Color.App.accent)
            }
        }
        .font(.subheadline)
        .padding(EdgeInsets(top: 4, leading: 6, bottom: 0, trailing: 6))
    }
}

final class MessageFooterUITableView: UIView {
    private let stack = UIStackView()
    private let pinImage = UIImageView(image: UIImage(systemName: "pin.fill"))
    private let timelabel = UILabel()
    private let editedLabel = UILabel()
    private let statusImage = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        timelabel.font = UIFont.uiiransansCaption2
        timelabel.textColor = Color.App.textSecondaryUIColor
        editedLabel.font = UIFont.uiiransansCaption2
        editedLabel.textColor = Color.App.textSecondaryUIColor
        pinImage.tintColor = Color.App.textPrimaryUIColor

        stack.spacing = 2
        stack.addArrangedSubview(timelabel)
        stack.addArrangedSubview(editedLabel)
        stack.addArrangedSubview(statusImage)
        stack.addArrangedSubview(pinImage)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusImage.widthAnchor.constraint(equalToConstant: 12),
            statusImage.heightAnchor.constraint(equalToConstant: 12),
            pinImage.widthAnchor.constraint(equalToConstant: 12),
            pinImage.heightAnchor.constraint(equalToConstant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
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
        let view = MessageFooterUITableView()
        view.setValues(viewModel: viewModel)
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
