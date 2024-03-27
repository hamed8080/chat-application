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
            if !viewModel.isMe {
                SelectMessageRadio()
            }

            if viewModel.isMe {
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                AvatarView(message: message)
            }

            MutableMessageView(viewModel: viewModel)

            if !viewModel.isMe {
                Spacer()
            }

            if viewModel.isMe {
                SelectMessageRadio()
            }
        }
        .environmentObject(viewModel)
        .padding(EdgeInsets(top: viewModel.isFirstMessageOfTheUser ? 6 : 1, leading: 8, bottom: 1, trailing: 8))
    }
}

struct SelectMessageRadio: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.isInSelectMode {
            VStack {
                Spacer()
                RadioButton(visible: $viewModel.isInSelectMode, isSelected: $viewModel.isSelected) { _ in
                    viewModel.toggleSelection()
                }
            }
            .padding(viewModel.paddings.radioPadding)
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
        .frame(minWidth: 128, maxWidth: viewModel.imageWidth ?? ThreadViewModel.maxAllowedWidth, alignment: viewModel.isMe ? .trailing : .leading)
        .simultaneousGesture(TapGesture().onEnded { _ in }, including: message.isVideo ? .subviews : .all)
    }
}

struct InnerMessage: View {
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        VStack(alignment: viewModel.isMe ? .trailing : .leading, spacing: 0) {
            if viewModel.isFirstMessageOfTheUser {
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
                    .environmentObject(viewModel.reactionsVM)
                MessageFooterView()
            }
        }
        .environmentObject(viewModel)
        .padding(viewModel.paddings.paddingEdgeInset)
        .background(MessageRowBackgroundView(viewModel: viewModel))
        .contentShape(viewModel.isLastMessageOfTheUser ? MessageRowBackground.withTail : MessageRowBackground.noTail)
        .customContextMenu(id: message.id, self: SelfContextMenu(viewModel: viewModel), menus: { ContextMenuContent(viewModel: viewModel) })
        .overlay(alignment: .center) { SelectMessageInsideClickOverlay() }
    }
}

struct MessageRowBackgroundView: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.isLastMessageOfTheUser {
            MessageRowBackground.withTail
                .fill(viewModel.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
                .scaleEffect(x: viewModel.isMe ? 1 : -1, y: 1)
        } else {
            MessageRowBackground.noTail
                .fill(viewModel.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
                .scaleEffect(x: viewModel.isMe ? 1 : -1, y: 1)
        }
    }
}

struct ContextMenuContent: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        VStack {
            ReactionMenuView()
                .environmentObject(viewModel.reactionsVM)
                .fixedSize()
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
