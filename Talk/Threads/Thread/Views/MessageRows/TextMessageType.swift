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
        HStack(spacing: 0) {
            if !viewModel.isMe {
                SelectMessageRadio()
            }

            if viewModel.isMe {
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                AvatarView(message: message, viewModel: viewModel)
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
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
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
            .padding(EdgeInsets(top: 0, leading: viewModel.isMe ? 8 : 0, bottom: 8, trailing: viewModel.isMe ? 8 : 0))
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
        VStack(alignment: viewModel.isMe ? .trailing : .leading, spacing: 10) {
            Group {
                MessageRowFileDownloader(viewModel: viewModel)
                MessageRowImageDownloader()
                MessageRowVideoDownloader(viewModel: viewModel)
                MessageRowAudioDownloader(viewModel: viewModel)
            }
            LocationRowView()
            GroupParticipantNameView()
            ReplyInfoMessageRow()  
            ForwardMessageRow()
            UploadMessageType()
            MessageTextView()
            JoinPublicLink(viewModel: viewModel)
            UnsentMessageView()
            Group {
                ReactionCountView()
                    .environmentObject(viewModel.reactionsVM)
                    .environmentObject(viewModel)
                MessageFooterView()
            }
        }
        .padding(viewModel.paddingEdgeInset)
        .background(
            MessageRowBackground.instance
                .fill(viewModel.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
                .scaleEffect(x: viewModel.isMe ? 1 : -1, y: 1)
        )
        .contentShape(MessageRowBackground.instance)
        .customContextMenu(id: message.id, self: SelfContextMenu(viewModel: viewModel), menus: { ContextMenuContent(viewModel: viewModel) })
        .overlay(alignment: .center) { SelectMessageInsideClickOverlay() }
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
            .onAppear {
                AppState.shared.cachedUser = .init(id: 1)
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
