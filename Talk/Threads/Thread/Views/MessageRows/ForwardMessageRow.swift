//
//  ForwardMessageRow.swift
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

final class ForwardMessageRow: UIButton {
    private let forwardStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let bar = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        configuration = .borderless()

        translatesAutoresizingMaskIntoConstraints = false
        forwardStaticLebel.translatesAutoresizingMaskIntoConstraints = false
        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false

        forwardStaticLebel.font = UIFont.uiiransansCaption3
        forwardStaticLebel.textColor = Color.App.textPrimaryUIColor
        forwardStaticLebel.text = "Message.forwardedFrom".localized()

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.textPrimaryUIColor
        participantLabel.numberOfLines = 1

        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        addSubview(forwardStaticLebel)
        addSubview(participantLabel)
        addSubview(bar)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.widthAnchor.constraint(equalToConstant: 1.5),
            forwardStaticLebel.topAnchor.constraint(equalTo: topAnchor),
            forwardStaticLebel.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
            participantLabel.topAnchor.constraint(equalTo: forwardStaticLebel.bottomAnchor, constant: 2),
            participantLabel.leadingAnchor.constraint(equalTo: forwardStaticLebel.leadingAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        let canShow = viewModel.message.forwardInfo != nil
        forwardStaticLebel.isHidden = !canShow
        bar.isHidden = !canShow
        participantLabel.text = viewModel.message.forwardInfo?.participant?.name
        participantLabel.isHidden = viewModel.message.forwardInfo?.participant?.name == nil
        registerGestures(viewModel: viewModel)
        isHidden = !canShow
        heightAnchor.constraint(equalToConstant: canShow ? 16 : 0).isActive = true
    }

    private func registerGestures(viewModel: MessageRowViewModel) {
        isUserInteractionEnabled = true
        let tap = MessageTapGestureRecognizer(target: self, action: #selector(onForwardTapped))
        tap.viewModel = viewModel
        addGestureRecognizer(tap)
    }

    @IBAction func onForwardTapped(_ sender: MessageTapGestureRecognizer) {
        print("on forward tapped")
    }
}

struct ForwardMessageRowWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = ForwardMessageRow()
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ForwardMessageRow_Previews: PreviewProvider {
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
            ForwardMessageRowWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.forwardInfo != nil })!)
            .previewDisplayName("Forward")
    }
}
