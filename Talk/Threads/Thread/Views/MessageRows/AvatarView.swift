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

struct AvatarView: View {
    @EnvironmentObject var navVM: NavigationModel
    var message: Message
    let viewModel: ThreadViewModel?

    @ViewBuilder var body: some View {
        if viewModel?.thread.group == true,
           !message.isMe(currentUserId: AppState.shared.user?.id),
           !(viewModel?.isSameUser(message: message) == true), message.participant != nil
        {
            HStack(spacing: 0) {
                if let image = message.participant?.image, let imageLoaderVM = viewModel?.threadsViewModel?.avatars(for: image) {
                    ImageLaoderView(imageLoader: imageLoaderVM, url: message.participant?.image, userName: message.participant?.name ?? message.participant?.username)
                        .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
                        .font(.iransansCaption)
                        .foregroundColor(.white)
                        .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(MessageRowViewModel.avatarSize / 2)
                } else {
                    Text(verbatim: String(message.participant?.name?.first ?? message.participant?.username?.first ?? " "))
                        .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
                        .font(.iransansCaption)
                        .foregroundColor(.white)
                        .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(MessageRowViewModel.avatarSize / 2)
                }
            }
            .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
            .onTapGesture {
                if let participant = message.participant {
                    navVM.append(participantDetail: participant)
                }
            }
        }
    }
}
