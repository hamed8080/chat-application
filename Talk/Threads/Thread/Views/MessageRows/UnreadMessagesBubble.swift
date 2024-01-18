//
//  UnreadMessagesBubble.swift
//  Talk
//
//  Created by hamed on 7/6/23.
//

import SwiftUI
import ChatModels
import TalkViewModels

//struct UnreadMessagesBubble: View {
//    var body: some View {
//        HStack {
//            Spacer()
//            Text("Messages.unreadMessages")
//                .font(.iransansCaption)
//                .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
//                .background(Color.App.hint)
//                .clipShape(RoundedRectangle(cornerRadius:(16)))
//                .foregroundColor(Color.App.white)
//            Spacer()
//        }
//    }
//}

final class UnreadMessagesBubble: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        label.font = UIFont.uiiransansCaption
        label.textColor = Color.App.textPrimaryUIColor
        label.textAlignment = .center
        label.text = "Messages.unreadMessages".localized()
        label.backgroundColor = Color.App.dividerPrimaryUIColor

        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
        ])
    }
}

struct UnreadMessagesBubbleWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        return UnreadMessagesBubble()
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
