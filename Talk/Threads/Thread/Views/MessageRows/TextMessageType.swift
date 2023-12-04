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

            MutableMessageView()

            if !viewModel.isMe {
                Spacer()
            }

            if viewModel.isMe {
                SelectMessageRadio()
            }
        }
        .environmentObject(viewModel)
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

struct SelectMessageRadio: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.isInSelectMode {
            VStack {
                Spacer()
                RadioButton(visible: $viewModel.isInSelectMode, isSelected: $viewModel.isSelected) { isSelected in
                    withAnimation(!viewModel.isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
                        viewModel.isSelected.toggle()
                        viewModel.threadVM?.selectedMessagesViewModel.animateObjectWillChange()
                        viewModel.animateObjectWillChange()
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: viewModel.isMe ? 8 : 0, bottom: 8, trailing: viewModel.isMe ? 8 : 0))
        }
    }
}

struct MutableMessageView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        VStack(alignment: viewModel.isMe ? .trailing : .leading, spacing: 10) {
            Group {
                MessageRowFileDownloader(viewModel: viewModel)
                MessageRowImageDownloader(viewModel: viewModel)
                MessageRowVideoDownloader(viewModel: viewModel)
                MessageRowAudioDownloader(viewModel: viewModel)
            }
            ReplyInfoMessageRow()
            ForwardMessageRow(viewModel: viewModel)
            UploadMessageType()
            GroupParticipantNameView()
            MessageTextView()
            JoinPublicLink(viewModel: viewModel)
            MapAddressTextView()
            UnsentMessageView()
            Group {
                ReactionCountView()
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
        .frame(minWidth: 128, maxWidth: MessageRowViewModel.maxAllowedWidth, alignment: viewModel.isMe ? .topTrailing : .topLeading)
        .simultaneousGesture(TapGesture().onEnded { _ in
            if let url = message.appleMapsURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }, including: message.isVideo ? .subviews : .all)
        .contentShape(MessageRowBackground.instance)
        .customContextMenu(id: message.id, self: selfMessage, menus: { contextMenuWithReactions })
        .onAppear {
            viewModel.calculate()
        }
    }

    private var selfMessage: some View {
        self
            .environmentObject(viewModel)
            .environmentObject(AppState.shared.objectsContainer.audioPlayerVM)
    }

    private var contextMenuWithReactions: some View {
        VStack {
            ReactionMenuView()
                .fixedSize()
            MessageActionMenu()
        }
        .environmentObject(viewModel)
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
