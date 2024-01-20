//
//  GroupParticipantNameView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels

//struct GroupParticipantNameView: View {
//    private var message: Message { viewModel.message }
//    @EnvironmentObject var viewModel: MessageRowViewModel
//    var canShowName: Bool {
//        !viewModel.isMe && viewModel.threadVM?.thread.group == true && viewModel.threadVM?.thread.type?.isChannelType == false
//    }
//
//    var body: some View {
//        if canShowName {
//            HStack {
//                Text(verbatim: message.participant?.name ?? "")
//                    .foregroundStyle(Color.App.purple)
//                    .font(.iransansBody)
//            }
//            .padding(.horizontal, 6)
//        }
//    }
//}

final class GroupParticipantNameView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        label.font = UIFont.uiiransansBody
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        label.textColor = viewModel.participantColor
        label.textAlignment = viewModel.isMe ? .right : .left
        label.text = viewModel.message.participant?.name ?? ""
    }
}

struct GroupParticipantNameViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = GroupParticipantNameView()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }

    private var padding: EdgeInsets {
        let hasAlreadyPadding = viewModel.message.replyInfo != nil || viewModel.message.forwardInfo != nil
        let padding: CGFloat = hasAlreadyPadding ? 0 : 4
        return .init(top: padding, leading: padding, bottom: 0, trailing: padding)
    }
}

struct GroupParticipantNameView_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel: MessageRowViewModel

        init(viewModel: MessageRowViewModel) {
            ThreadViewModel.maxAllowedWidth = 340
            self._viewModel = StateObject(wrappedValue: viewModel)
            Task {
                await viewModel.performaCalculation()
                await viewModel.asyncAnimateObjectWillChange()
            }
        }

        var body: some View {
            GroupParticipantNameViewWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.groupParticipantNameVM)
    }
}
