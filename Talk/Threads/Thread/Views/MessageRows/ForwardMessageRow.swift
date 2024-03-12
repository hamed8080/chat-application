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
    private let hStackWithBar = UIStackView()
    private let vStack = UIStackView()
    private let hStack = UIStackView()
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
        hStackWithBar.translatesAutoresizingMaskIntoConstraints = false
        vStack.translatesAutoresizingMaskIntoConstraints = false

        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        configuration = .borderless()

        forwardStaticLebel.font = UIFont.uiiransansCaption3
        forwardStaticLebel.textColor = Color.App.textPrimaryUIColor
        forwardStaticLebel.text = "Message.forwardedFrom".localized()

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.textPrimaryUIColor
        participantLabel.numberOfLines = 1

        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.alignment = .leading
        vStack.layoutMargins = UIEdgeInsets(all: 8)
        vStack.isLayoutMarginsRelativeArrangement = true

        hStack.axis = .horizontal
        hStack.spacing = 4

        vStack.addArrangedSubview(forwardStaticLebel)
        vStack.addArrangedSubview(participantLabel)
        vStack.addArrangedSubview(hStack)

        hStackWithBar.axis = .horizontal
        hStackWithBar.spacing = 2
        hStackWithBar.addArrangedSubview(bar)
        hStackWithBar.addArrangedSubview(vStack)
        addSubview(hStackWithBar)

        NSLayoutConstraint.activate([
            bar.heightAnchor.constraint(equalTo: hStackWithBar.heightAnchor),
            bar.widthAnchor.constraint(equalToConstant: 1.5),
            hStackWithBar.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            hStackWithBar.topAnchor.constraint(equalTo: topAnchor),
            hStackWithBar.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        participantLabel.text = viewModel.message.forwardInfo?.participant?.name
        participantLabel.isHidden = viewModel.message.forwardInfo?.participant?.name == nil
        registerGestures(viewModel: viewModel)
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
        view.setValues(viewModel: viewModel)
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
