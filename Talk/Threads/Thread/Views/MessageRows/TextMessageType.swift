//
//  TextMessageType.swift
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
import Combine
import TalkModels
import TalkExtensions

struct TextMessageType: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    let viewModel: MessageRowViewModel

    var body: some View {
        textMessageView
    }

    var textMessageView: some View {
        HStack(spacing: 0) {
            if !viewModel.calculatedMessage.isMe {
                SelectMessageRadio()
            }

            if viewModel.calculatedMessage.isMe {
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                AvatarView(message: message)
            }

            MutableMessageView(viewModel: viewModel)

            if !viewModel.calculatedMessage.isMe {
                Spacer()
            }

            if viewModel.calculatedMessage.isMe {
                SelectMessageRadio()
            }
        }
        .environmentObject(viewModel)
        .padding(EdgeInsets(top: viewModel.calculatedMessage.isFirstMessageOfTheUser ? 6 : 1, leading: 8, bottom: 1, trailing: 8))
    }
}

struct SelectMessageRadio: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.state.isInSelectMode {
            VStack {
                Spacer()
                RadioButton(visible: $viewModel.state.isInSelectMode, isSelected: $viewModel.state.isSelected) { _ in
                    viewModel.toggleSelection()
                }
            }
            .padding(viewModel.sizes.paddings.radioPadding)
        }
    }
}

struct MutableMessageView: View {
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        HStack {
           InnerMessage(viewModel: viewModel)
        }
        .frame(minWidth: 128, maxWidth: viewModel.sizes.imageWidth ?? ThreadViewModel.maxAllowedWidth, alignment: viewModel.calculatedMessage.isMe ? .trailing : .leading)
        .simultaneousGesture(TapGesture().onEnded { _ in }, including: message.isVideo ? .subviews : .all)
    }
}

struct InnerMessage: View {
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        VStack(alignment: viewModel.calculatedMessage.isMe ? .trailing : .leading, spacing: 0) {
            if viewModel.calculatedMessage.isFirstMessageOfTheUser {
                GroupParticipantNameView()
            }
            if viewModel.rowType.isReply {
                ReplyInfoMessageRow()
            }
            if viewModel.rowType.isForward {
                ForwardMessageRow()
            }
            Group {
                if viewModel.rowType.isMap {
                    LocationRowView()
                }
                if viewModel.rowType.isFile {
                    MessageRowFileView()
                }
                if viewModel.rowType.isImage {
                    MessageRowImageView()
                }
                if viewModel.rowType.isVideo {
                    MessageRowVideoView()
                }
                if viewModel.rowType.isAudio {
                    MessageRowAudioView()
                }
            }

            MessageTextView()

            if viewModel.rowType.isPublicLink {
                JoinPublicLink(viewModel: viewModel)
            }
            if viewModel.rowType.isUnSent {
                UnsentMessageView()
            }
            Group {
                ReactionCountView()
                MessageFooterView()
            }
        }
        .environmentObject(viewModel)
        .padding(viewModel.sizes.paddings.paddingEdgeInset)
        .background(MessageRowBackgroundView(viewModel: viewModel))
        .contentShape(viewModel.calculatedMessage.isLastMessageOfTheUser ? MessageRowBackground.withTail : MessageRowBackground.noTail)
        .customContextMenu(id: message.id, self: SelfContextMenu(viewModel: viewModel), menus: { ContextMenuContent(viewModel: viewModel) })
        .overlay(alignment: .center) { SelectMessageInsideClickOverlay() }
    }
}

struct MessageRowBackgroundView: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.calculatedMessage.isLastMessageOfTheUser {
            MessageRowBackground.withTail
                .fill(viewModel.calculatedMessage.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
                .scaleEffect(x: viewModel.calculatedMessage.isMe ? 1 : -1, y: 1)
        } else {
            MessageRowBackground.noTail
                .fill(viewModel.calculatedMessage.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
                .scaleEffect(x: viewModel.calculatedMessage.isMe ? 1 : -1, y: 1)
        }
    }
}

struct ContextMenuContent: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        VStack {
            if viewModel.calculatedMessage.isInTwoWeekPeriod {
                ReactionMenuView()
                    .environmentObject(viewModel.threadVM?.reactionViewModel ?? .init())
                    .environmentObject(viewModel)
                    .fixedSize()
            }
            MessageActionMenu()
        }
        .id("SelfContextMenu\(viewModel.message.id ?? 0)")
        .environmentObject(viewModel)
        .onAppear {
            hideKeyboard()
        }
    }
}

struct SelfContextMenu: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        HStack {
            InnerMessage(viewModel: viewModel)
                .environmentObject(viewModel)
                .environmentObject(AppState.shared.objectsContainer.audioPlayerVM)
        }
        .id("SelfContextMenu\(viewModel.message.id ?? 0)")
        .frame(maxWidth: ThreadViewModel.maxAllowedWidth)
    }
}

struct TextMessageType_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel: MessageRowViewModel = .init(
            message: .init(
                id: 1,
                message: "TEST",
                messageType: .text,
                ownerId: 1,
                seen: true,
                time: UInt(Date().millisecondsSince1970),
                participant: Participant(id: 0, name: "John Doe")
            ),
            viewModel: .init(thread: Conversation(id: 1))
        )

        var body: some View {
            ScrollView {
                TextMessageType(viewModel: viewModel)
            }
            .environmentObject(viewModel)
            .environmentObject(NavigationModel())           
        }
    }

    static var previews: some View {
        Preview()
    }
}
