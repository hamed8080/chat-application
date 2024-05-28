//
//  AvatarView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct AvatarView: View {
    var message: any HistoryMessageProtocol
    @EnvironmentObject var viewModel: MessageRowViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }

    static func emptyViewSender(trailing: CGFloat = 8) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: MessageRowSizes.avatarSize, height: MessageRowSizes.avatarSize)
            .padding(.trailing, trailing)
    }

    @ViewBuilder var body: some View {
        if hiddenView {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        } else if showAvatarOrUserName {
            HStack(spacing: 0) {
                if let avatarImageLoader = viewModel.avatarImageLoader {
                    ImageLoaderView(imageLoader: avatarImageLoader)
                        .id(imageLoaderId)
                        .font(.iransansCaption)
                        .foregroundColor(.white)
                        .frame(width: MessageRowSizes.avatarSize, height: MessageRowSizes.avatarSize)
                        .background(viewModel.calMessage.avatarColor)
                        .clipShape(RoundedRectangle(cornerRadius:(MessageRowSizes.avatarSize / 2)))
                } else {
                    Text(verbatim: viewModel.calMessage.avatarSplitedCharaters)
                        .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
                        .font(.iransansCaption)
                        .foregroundColor(.white)
                        .frame(width: MessageRowSizes.avatarSize, height: MessageRowSizes.avatarSize)
                        .background(viewModel.calMessage.avatarColor)
                        .clipShape(RoundedRectangle(cornerRadius:(MessageRowSizes.avatarSize / 2)))
                }
            }
            .frame(width: MessageRowSizes.avatarSize, height: MessageRowSizes.avatarSize)
            .padding(.trailing, 2)
            .onTapGesture {
                if let participant = message.participant {
                    AppState.shared.openThread(participant: participant)
                }
            }
        } else if isSameUser {
            /// Place a empty view to show the message has sent by the same user.
            AvatarView.emptyViewSender(trailing: viewModel.calMessage.isLastMessageOfTheUser ? 8 : 0)
        }
    }

    private var hiddenView: Bool {
        viewModel.calMessage.state.isInSelectMode || (viewModel.threadVM?.thread.group ?? false) == false
    }

    private var imageLoaderId: String {
        "\(message.participant?.image ?? "")\(message.participant?.id ?? 0)"
    }

    private var showAvatarOrUserName: Bool {
        !viewModel.calMessage.isMe && viewModel.calMessage.isLastMessageOfTheUser && viewModel.calMessage.isCalculated
    }

    private var isSameUser: Bool {
        !viewModel.calMessage.isMe && !viewModel.calMessage.isLastMessageOfTheUser
    }
}
