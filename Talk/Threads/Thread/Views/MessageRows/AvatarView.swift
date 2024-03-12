//
//  AvatarView.swift
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

final class AvatarView: UIView {
    private let label = UILabel()
    private let image = UIImageView()
    public var viewModel: MessageRowViewModel!
    var message: Message { viewModel.message }
    var avatarVM: ImageLoaderViewModel? { viewModel.avatarImageLoader }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        label.font = UIFont.uiiransansCaption
        label.textColor = Color.App.whiteUIColor
        label.textAlignment = .center
        label.backgroundColor = Color.App.color1UIColor?.withAlphaComponent(0.4)
        label.layer.cornerRadius = MessageRowViewModel.avatarSize / 2
        label.layer.masksToBounds = true

        image.backgroundColor = Color.App.color1UIColor?.withAlphaComponent(0.4)
        image.layer.cornerRadius = MessageRowViewModel.avatarSize / 2
        image.layer.masksToBounds = true

        addSubview(image)
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        image.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize),
            image.heightAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize),
            label.widthAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize),
            label.heightAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        let showImage = avatarVM?.image != nil
        label.isHidden = showImage
        image.isHidden = !showImage
        if showImage {
            image.image = avatarVM?.image
        } else {
            label.text = String(message.participant?.name?.first ?? message.participant?.username?.first ?? " ")
        }
        if avatarVM?.isImageReady == false {
            avatarVM?.fetch()
        }

        if viewModel.isNextMessageTheSameUser {
            widthAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize).isActive = true
            heightAnchor.constraint(equalToConstant: MessageRowViewModel.avatarSize).isActive = true
            image.isHidden = true
        } else {
            let canShow = !viewModel.isMe && !viewModel.isNextMessageTheSameUser && viewModel.threadVM?.thread.group == true
            isHidden = !canShow
            widthAnchor.constraint(equalToConstant: canShow ? MessageRowViewModel.avatarSize : 0 ).isActive = true
            heightAnchor.constraint(equalToConstant: canShow ? MessageRowViewModel.avatarSize : 0 ).isActive = true
            print("can show is:\(canShow)")
        }
    }

    private var hiddenView: Bool {
        viewModel.isInSelectMode || (viewModel.threadVM?.thread.group ?? false) == false
    }

    private var imageLoaderId: String {
        "\(message.participant?.image ?? "")\(message.participant?.id ?? 0)"
    }

    private var showAvatarOrUserName: Bool {
        !viewModel.isMe && !viewModel.isNextMessageTheSameUser && viewModel.isCalculated
    }

    private var isSameUser: Bool {
        !viewModel.isMe && viewModel.isNextMessageTheSameUser
    }
}

struct AvatarViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = AvatarView()
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}
