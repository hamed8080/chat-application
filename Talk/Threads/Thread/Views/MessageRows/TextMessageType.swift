//
//  TextMessageType.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import Combine
import TalkModels
import TalkExtensions

struct TextMessageType: View {
    private var message: any HistoryMessageProtocol { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    let viewModel: MessageRowViewModel

    var body: some View {
        textMessageView
    }

    var textMessageView: some View {
        HStack(spacing: 0) {
            if !viewModel.calMessage.isMe {
                SelectMessageRadio()
            }

            if viewModel.calMessage.isMe {
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                AvatarView(message: message)
            }

            MutableMessageView(viewModel: viewModel)

            if !viewModel.calMessage.isMe {
                Spacer()
            }

            if viewModel.calMessage.isMe {
                SelectMessageRadio()
            }
        }
        .environmentObject(viewModel)
        .padding(EdgeInsets(top: viewModel.calMessage.isFirstMessageOfTheUser ? 6 : 1, leading: 8, bottom: 1, trailing: 8))
    }
}

struct SelectMessageRadio: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.calMessage.state.isInSelectMode {
            VStack {
                Spacer()
                RadioButton(visible: $viewModel.calMessage.state.isInSelectMode, isSelected: $viewModel.calMessage.state.isSelected) { _ in
                    viewModel.toggleSelection()
                }
            }
            .padding(viewModel.calMessage.sizes.paddings.radioPadding)
        }
    }
}

struct MutableMessageView: View {
    let viewModel: MessageRowViewModel
    private var message: any HistoryMessageProtocol { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        HStack {
           InnerMessage(viewModel: viewModel)
        }
        .frame(minWidth: 128, maxWidth: viewModel.calMessage.sizes.imageWidth ?? ThreadViewModel.maxAllowedWidth, alignment: viewModel.calMessage.isMe ? .trailing : .leading)
        .simultaneousGesture(TapGesture().onEnded { _ in }, including: message.isVideo ? .subviews : .all)
    }
}

struct InnerMessage: View {
    let viewModel: MessageRowViewModel
    private var message: any HistoryMessageProtocol { viewModel.message }

    var body: some View {
        VStack(alignment: viewModel.calMessage.isMe ? .trailing : .leading, spacing: 0) {
            if viewModel.calMessage.isFirstMessageOfTheUser {
                GroupParticipantNameView()
            }
            if viewModel.calMessage.rowType.isReply {
                ReplyInfoMessageRow()
            }
            if viewModel.calMessage.rowType.isForward {
                ForwardMessageRow()
            }
            Group {
                if viewModel.calMessage.rowType.isMap {
                    LocationRowView()
                }
                if viewModel.calMessage.rowType.isFile {
                    MessageRowFileView()
                }
                if viewModel.calMessage.rowType.isImage {
                    MessageRowImageView()
                }
                if viewModel.calMessage.rowType.isVideo {
                    MessageRowVideoView()
                }
                if viewModel.calMessage.rowType.isAudio {
                    MessageRowAudioView()
                }
            }

            MessageTextView()

            if viewModel.calMessage.rowType.isPublicLink {
                JoinPublicLink(viewModel: viewModel)
            }
            if viewModel.calMessage.rowType.isUnSent {
                UnsentMessageView()
            }
            Group {
                ReactionCountView()
                MessageFooterView()
            }
        }
        .environmentObject(viewModel)
        .padding(viewModel.calMessage.sizes.paddings.paddingEdgeInset)
        .background(MessageRowBackgroundView(viewModel: viewModel))
        .contentShape(viewModel.calMessage.isLastMessageOfTheUser ? MessageRowBackground.withTail : MessageRowBackground.noTail)
        .customContextMenu(id: message.id, self: SelfContextMenu(viewModel: viewModel), menus: { ContextMenuContent(viewModel: viewModel) })
        .overlay(alignment: .center) { SelectMessageInsideClickOverlay() }
    }
}

struct MessageRowBackgroundView: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.calMessage.isLastMessageOfTheUser {
            MessageRowBackground.withTail
                .fill(viewModel.calMessage.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
                .scaleEffect(x: viewModel.calMessage.isMe ? 1 : -1, y: 1)
        } else {
            MessageRowBackground.noTail
                .fill(viewModel.calMessage.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
                .scaleEffect(x: viewModel.calMessage.isMe ? 1 : -1, y: 1)
        }
    }
}

struct ContextMenuContent: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        VStack {
            if viewModel.calMessage.isInTwoWeekPeriod {
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
            message: Message(
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
