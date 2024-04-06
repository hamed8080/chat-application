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

final class GroupParticipantNameView: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        font = UIFont.uiiransansBoldBody
        numberOfLines = 1
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let name = viewModel.groupMessageParticipantName
        textColor = viewModel.participantColor
        textAlignment = viewModel.isMe ? .right : .left
        text = name
        isHidden = name == nil
    }
}

struct GroupParticipantNameViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = GroupParticipantNameView()
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct GroupParticipantNameView_Previews: PreviewProvider {
    struct Preview: View {
        var viewModel: MessageRowViewModel

        init(viewModel: MessageRowViewModel) {
            ThreadViewModel.maxAllowedWidth = 340
            self.viewModel = viewModel
        }

        var body: some View {
            GroupParticipantNameViewWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.groupParticipantNameVM)
    }
}
