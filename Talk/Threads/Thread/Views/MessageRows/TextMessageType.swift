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
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
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
                        viewModel.animateObjectWillChange()
                    }
                    viewModel.threadVM?.animateObjectWillChange()
                }
            }
            .padding(viewModel.isMe ? .leading : .trailing, 8)
            .padding(.bottom, 8)
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
            ForwardMessageRow()
            UploadMessageType(message: message, maxWidth: viewModel.maxWidth)
            GroupParticipantNameView()
            MessageTextView()
            MapAddressTextView()
            UnsentMessageView()
            Group {
                ReactionCountView(viewModel: viewModel)
                MessageFooterView()
            }
        }
        .padding(.top, message.isImage ? 0 : 6)
        .padding(4)
        .frame(maxWidth: viewModel.maxWidth, alignment: viewModel.isMe ? .trailing : .leading)
        .contentShape(Rectangle())
        .background(viewModel.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
        .overlay {
            if viewModel.isHighlited {
                Color.App.primary.opacity(0.1)
            }
        }
        .cornerRadius(12, corners: [.topLeft, .topRight])
        .cornerRadius(bottomLeftCorner, corners: [.bottomLeft])
        .cornerRadius(bottomRightCorner, corners: [.bottomRight])
        .overlay(alignment: .bottom) {
            MessageBubbleTail()
        }
        .simultaneousGesture(TapGesture().onEnded { _ in
            if let url = message.appleMapsURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }, including: message.isVideo ? .subviews : .all)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .customContextMenu(self: selfMessage, menus: { contextMenuWithReactions })
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
            MessageActionMenu()
        }
        .environmentObject(viewModel)
    }

    private var bottomLeftCorner: CGFloat {
        if viewModel.isMe {
            return 12
        } else if viewModel.isNextMessageTheSameUser {
            return 12
        } else {
            return 0
        }
    }

    private var bottomRightCorner: CGFloat {
        if viewModel.isMe {
            return 0
        } else if viewModel.isNextMessageTheSameUser {
            return 12
        } else {
            return 12
        }
    }

    var textAlignment: TextAlignment {
        if !viewModel.isEnglish && !viewModel.isMe {
            return .leading
        } else if viewModel.isMe && !viewModel.isEnglish {
            return .leading
        } else if !viewModel.isMe && viewModel.isEnglish {
            return .trailing
        } else {
            return .leading
        }
    }
}

struct MessageBubbleTail: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        HStack {
            if viewModel.isMe {
                Spacer()
            }
            if !viewModel.isNextMessageTheSameUser {
                Image(uiImage: viewModel.isMe ? Message.trailingTail : Message.leadingTail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 9, height: 18)
                    .offset(x: viewModel.isMe ? 9 : -9)
                    .foregroundStyle(viewModel.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
            }
            if !viewModel.isMe {
                Spacer()
            }
        }
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
