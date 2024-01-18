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

//struct AvatarView: View {
//    @EnvironmentObject var navVM: NavigationModel
//    var message: Message
//    @StateObject var viewModel: MessageRowViewModel
//    var threadVM: ThreadViewModel? { viewModel.threadVM }
//
//    static var emptyViewSender: some View {
//        Rectangle()
//            .fill(Color.clear)
//            .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
//            .padding(.trailing, 8)
//    }
//
//    static var emptyP2PSender: some View {
//        Rectangle()
//            .fill(Color.clear)
//            .frame(width: 8)
//            .padding(.trailing, 8)
//    }
//
//    @ViewBuilder var body: some View {
//        if hiddenView {
//            EmptyView()
//                .frame(width: 0, height: 0)
//                .hidden()
//        } else if showAvatarOrUserName {
//            HStack(spacing: 0) {
//                if let avatarImageLoader = viewModel.avatarImageLoader {
//                    ImageLoaderView(imageLoader: avatarImageLoader)
//                        .id(imageLoaderId)
//                        .font(.iransansCaption)
//                        .foregroundColor(.white)
//                        .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
//                        .background(Color.App.blue.opacity(0.4))
//                        .clipShape(RoundedRectangle(cornerRadius:(MessageRowViewModel.avatarSize / 2)))
//                } else {
//                    Text(verbatim: String(message.participant?.name?.first ?? message.participant?.username?.first ?? " "))
//                        .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
//                        .font(.iransansCaption)
//                        .foregroundColor(.white)
//                        .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
//                        .background(Color.App.blue.opacity(0.4))
//                        .clipShape(RoundedRectangle(cornerRadius:(MessageRowViewModel.avatarSize / 2)))
//                }
//            }
//            .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
//            .padding(.trailing, 2)
//            .onTapGesture {
//                if let participant = message.participant {
//                    navVM.append(participantDetail: participant)
//                }
//            }
//        } else if isSameUser {
//            /// Place a empty view to show the message has sent by the same user.
//            AvatarView.emptyViewSender
//        }
//    }
//
//    private var hiddenView: Bool {
//        viewModel.isInSelectMode || (viewModel.threadVM?.thread.group ?? false) == false
//    }
//
//    private var imageLoaderId: String {
//        "\(message.participant?.image ?? "")\(message.participant?.id ?? 0)"
//    }
//
//    private var showAvatarOrUserName: Bool {
//        !viewModel.isMe && !viewModel.isNextMessageTheSameUser && viewModel.isCalculated
//    }
//
//    private var isSameUser: Bool {
//        !viewModel.isMe && viewModel.isNextMessageTheSameUser
//    }
//}

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

    public func setValues(viewModel: MessageRowViewModel) {
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
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}
