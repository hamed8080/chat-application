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
        HStack(spacing: 8) {
            if !viewModel.isMe {
                SelectMessageRadio()
            }

            if viewModel.isMe {
                Spacer()
            }

            MutableMessageView()
            EmojiIcon()

            if !viewModel.isMe {
                Spacer()
            }

            if viewModel.isMe {
                SelectMessageRadio()
            }
        }
        .overlay(alignment: .topLeading) {
            OverlayEmojiViews()
        }
        .environmentObject(viewModel)
    }
}

struct SelectMessageRadio: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        ZStack {
            Image(systemName: viewModel.isSelected ? "checkmark.circle.fill" : "circle")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .font(.title)
                .symbolRenderingMode(.palette)
                .foregroundStyle(viewModel.isSelected ? Color.bgChatContainer : Color.hint, Color.main)
        }
        .frame(width: viewModel.isInSelectMode ? 22 : 0.001, height: viewModel.isInSelectMode ? 22 : 0.001, alignment: .center)
        .padding(viewModel.isInSelectMode ? 24 : 0.001)
        .scaleEffect(x: viewModel.isInSelectMode ? 1.0 : 0.001, y: viewModel.isInSelectMode ? 1.0 : 0.001, anchor: .center)
        .onTapGesture {
            withAnimation(!viewModel.isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
                viewModel.isSelected.toggle()
                viewModel.animateObjectWillChange()
            }
            viewModel.threadVM?.animateObjectWillChange()
        }
    }
}

struct MutableMessageView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
        VStack(spacing: 0) {
            if message.replyInfo != nil {
                ReplyInfoMessageRow()
                    .background(Color.replyBg)
                    .environmentObject(viewModel)
            }

            if let forwardInfo = message.forwardInfo {
                ForwardMessageRow(forwardInfo: forwardInfo)
            }

            if message.isUploadMessage {
                UploadMessageType(message: message)
                    .frame(maxHeight: 320)
            }

            ZStack(alignment: .topLeading) {
                if message.isFileType, message.id ?? 0 > 0, let downloadVM = viewModel.downloadFileVM {
                    DownloadFileView(viewModel: downloadVM)
                        .frame(maxHeight: 320)
                        .clipped()
                        .contentShape(Rectangle())
                }
                AvatarView(message: message, viewModel: threadVM)
            }

            if let fileName = message.fileName {
                Text("\(fileName)\(message.fileExtension ?? "")")
                    .foregroundColor(.darkGreen.opacity(0.8))
                    .font(.caption)
                    .clipped()
            }

            // TODO: TEXT must be alignment and image must be fit
            Text(viewModel.markdownTitle)
                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                .padding(8)
                .font(.iransansBody)
                .foregroundColor(.messageText)
                .clipped()

            if let addressDetail = viewModel.addressDetail {
                Text(addressDetail)
                    .foregroundColor(.darkGreen.opacity(0.8))
                    .font(.caption)
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
                .font(.caption.bold())
            }

            MessageFooterView(message: message)
                .padding(.bottom, 8)
                .padding([.leading, .trailing])
        }
        .frame(maxWidth: viewModel.widthOfRow)
        .padding([.leading, .trailing], 0)
        .contentShape(Rectangle())
        .background(viewModel.isMe ? Color.bgMessageMe : Color.bgMessage)
        .overlay {
            if viewModel.isHighlited {
                Color.blue.opacity(0.3)
            }
        }
        .cornerRadius(12, corners: [.topLeft, .topRight, viewModel.isMe ? .bottomLeft : .bottomRight])
        .overlay(alignment: .bottom) {
            HStack {
                if viewModel.isMe {
                    Spacer()
                }
                Image(uiImage: viewModel.isMe ? Message.trailingTail : Message.leadingTail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 9, height: 18)
                    .offset(x: viewModel.isMe ? 9 : -9)
                    .foregroundStyle(viewModel.isMe ? Color.bgMessageMe : Color.bgMessage)
                if !viewModel.isMe {
                    Spacer()
                }
            }
        }
        .simultaneousGesture(TapGesture().onEnded { _ in
            if let url = message.appleMapsURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }, including: message.isVideo ? .subviews : .all)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            MessageActionMenu()
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.calculate()
        }
    }
}


struct TextMessageType_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel: MessageRowViewModel = .init(
            message: .init(
                id: 1,
                message: "TEST",
                seen: true,
                time: UInt(Date().millisecondsSince1970), participant: Participant(id: 0, name: "John Doe")
            ),
            viewModel: .init(thread: Conversation(id: 1))
        )

        var body: some View {
            NavigationSplitView {} content: {} detail: {
                ScrollView {
                    TextMessageType(viewModel: viewModel)
                }
            }
            .environmentObject(viewModel)
            .environmentObject(NavigationModel())
        }
    }

    static var previews: some View {
        Preview()
    }
}
