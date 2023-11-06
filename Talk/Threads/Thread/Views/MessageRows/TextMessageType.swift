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

struct TextMessageType: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    let viewModel: MessageRowViewModel
    @State private var showReactionsOverlay = false

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
    let padding: CGFloat = 4
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.isMe {
                HStack {
                    Text(verbatim: message.participant?.name ?? "")
                        .foregroundStyle(Color.App.purple)
                        .font(.iransansBody)
                    Spacer()
                }
            }

            if message.replyInfo != nil {
                ReplyInfoMessageRow()
                    .environmentObject(viewModel)
            }

            ForwardMessageRow()

            if message.isUploadMessage {
                UploadMessageType(message: message)
                    .frame(maxHeight: viewModel.widthOfRow - padding)
            }

            if message.isFileType, message.id ?? 0 > 0, let downloadVM = viewModel.downloadFileVM {
                DownloadFileView(viewModel: downloadVM)
                    .frame(maxHeight: message.isImage ? viewModel.widthOfRow - padding : nil)
                    .clipped()
                    .contentShape(Rectangle())
                    .cornerRadius(8)
            }

            // TODO: TEXT must be alignment and image must be fit
            if !message.messageTitle.isEmpty {
                Text(viewModel.markdownTitle)
                    .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                    .padding(8)
                    .font(.iransansBody)
                    .foregroundColor(Color.App.text)
                    .clipped()
            }

            if let addressDetail = viewModel.addressDetail {
                Text(addressDetail)
                    .foregroundStyle(Color.App.hint)
                    .font(.iransansCaption)
                    .padding([.leading, .trailing])
            }

            if message.isUnsentMessage {
                HStack {
                    Spacer()
                    Button("Messages.resend") {
                        threadVM?.resendUnsetMessage(message)
                    }

                    Button("General.cancel", role: .destructive) {
                        threadVM?.cancelUnsentMessage(message.uniqueId ?? "")
                    }
                }
                .padding()
                .font(.iransansCaption.bold())
            }

            Group {
                ReactionCountView(message: message)
                MessageFooterView(message: message)
            }
        }
        .frame(maxWidth: viewModel.widthOfRow)
        .padding(message.isImage ? 4 : 10)
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
        /// We should pass the width of the row when it gets updated to the context menu to get proper width of the view in modifier.
        .customContextMenu(self: self
            .environmentObject(viewModel)
            .environmentObject(AppState.shared.objectsContainer.audioPlayerVM), width: viewModel.widthOfRow) {
            MessageActionMenu()
                .environmentObject(viewModel)
        } topView: {
            ReactionMenuView()
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.calculate()
        }
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
