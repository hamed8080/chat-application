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
    @StateObject var viewModel: MessageRowViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }

    static var emptyViewSender: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
            .padding(.trailing, 8)
    }

    static var emptyP2PSender: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 8)
            .padding(.trailing, 8)
    }

    @ViewBuilder var body: some View {
        if viewModel.isInSelectMode || (viewModel.threadVM?.thread.group ?? false) == false {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        } else if !viewModel.isMe, !viewModel.isNextMessageTheSameUser, viewModel.isCalculated {
            HStack(spacing: 0) {
                if let avatarImageLoader = viewModel.avatarImageLoader {
                    ImageLaoderView(imageLoader: avatarImageLoader, url: message.participant?.image, userName: message.participant?.name ?? message.participant?.username)
                        .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
                        .font(.iransansCaption)
                        .foregroundColor(.white)
                        .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
                        .background(Color.App.blue.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius:(MessageRowViewModel.avatarSize / 2)))
                } else {
                    Text(verbatim: String(message.participant?.name?.first ?? message.participant?.username?.first ?? " "))
                        .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
                        .font(.iransansCaption)
                        .foregroundColor(.white)
                        .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
                        .background(Color.App.blue.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius:(MessageRowViewModel.avatarSize / 2)))
                }
            }
            .frame(width: MessageRowViewModel.avatarSize, height: MessageRowViewModel.avatarSize)
            .padding(.trailing, 8)
            .onTapGesture {
                if let participant = message.participant {
                    navVM.append(participantDetail: participant)
                }
            }
        } else if !viewModel.isMe, viewModel.isNextMessageTheSameUser {
            /// Place a empty view to show the message has sent by the same user.
            AvatarView.emptyViewSender
        }
    }
}
