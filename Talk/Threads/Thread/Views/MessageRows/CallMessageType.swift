//
//  CallMessageType.swift
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
import UIKit

final class CallEventUITableViewCell: UITableViewCell {
    private let stack = UIStackView()
    private static let startCallImage = UIImage(systemName: "phone.arrow.up.right.fill")
    private static let endCallImage = UIImage(systemName: "phone.down.fill")
    private var statusImage = UIImageView(image: CallEventUITableViewCell.startCallImage)
    private let dateLabel = UILabel()
    private let typeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {

        stack.translatesAutoresizingMaskIntoConstraints = false

        typeLabel.font = UIFont.uiiransansBody
        dateLabel.font = UIFont.uiiransansBody

        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12

        stack.addArrangedSubview(typeLabel)
        stack.addArrangedSubview(dateLabel)
        stack.addArrangedSubview(statusImage)
        stack.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        stack.layer.cornerRadius = 14
        stack.layer.masksToBounds = true
        stack.layoutMargins = .init(top: 4, left: 16, bottom: 4, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        contentView.backgroundColor = .yellow
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            statusImage.widthAnchor.constraint(equalToConstant: 18),
            statusImage.heightAnchor.constraint(equalToConstant: 18),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let message = viewModel.message
        let isStarted = message.type == .startCall
        statusImage.image = isStarted ? CallEventUITableViewCell.startCallImage : CallEventUITableViewCell.endCallImage
        statusImage.tintColor = isStarted ? UIColor.green : Color.App.redUIColor
        typeLabel.text = isStarted ? "Thread.callStarted".localized() : "Thread.callEnded".localized()
        let date = Date(milliseconds: Int64(message.time ?? 0))
        dateLabel.text = "\(date.localFormattedTime ?? "")"
    }
}

struct CallMessageWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = CallEventUITableViewCell()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

struct CallMessageWapper_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let message = Message(id: 1, messageType: .startCall, time: 155600555)
            let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
            CallMessageWapper(viewModel: viewModel)
        }
    }
}
