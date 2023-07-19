//
//  TextMessageType.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct TextMessageType: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel
    @State private var isSelected = false
    private var isMe: Bool { message.isMe(currentUserId: AppState.shared.user?.id) }

    var body: some View {
        HStack(spacing: 8) {
            if !isMe {
                selectRadio
            }
            if message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }
            VStack(spacing: 0) {
                AvatarView(message: message, viewModel: threadVM)
                if message.replyInfo != nil {
                    ReplyInfoMessageRow()
                        .environmentObject(viewModel)
                }

                if let forwardInfo = message.forwardInfo {
                    ForwardMessageRow(forwardInfo: forwardInfo)
                }

                if message.isUploadMessage {
                    UploadMessageType(message: message)
                        .frame(maxHeight: 320)
                }

                if message.isFileType, message.id ?? 0 > 0 {
                    DownloadFileView(message: message)
                        .environmentObject(viewModel.downloadFileVM)
                        .frame(maxHeight: 320)
                }

                if let fileName = message.fileName {
                    Text("\(fileName)\(message.fileExtension ?? "")")
                        .foregroundColor(.darkGreen.opacity(0.8))
                        .font(.caption)
                }

                // TODO: TEXT must be alignment and image must be fit
                Text(viewModel.markdownTitle)
                    .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                    .padding(8)
                    .font(.iransansBody)
                    .foregroundColor(.black)

                if let addressDetail = viewModel.addressDetail {
                    Text(addressDetail)
                        .foregroundColor(.darkGreen.opacity(0.8))
                        .font(.caption)
                        .padding([.leading, .trailing])
                }

                if message.isUnsentMessage {
                    HStack {
                        Spacer()
                        Button("Resend".uppercased()) {
                            threadVM?.resendUnsetMessage(message)
                        }

                        Button("Cancel".uppercased(), role: .destructive) {
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
            .frame(maxWidth: viewModel.widthOfRow, alignment: .leading)
            .padding([.leading, .trailing], 0)
            .contentShape(Rectangle())
            .background(message.isMe(currentUserId: AppState.shared.user?.id) ? Color.chatMeBg : Color.chatSenderBg)
            .overlay {
                if viewModel.isHighlited {
                    Color.blue.opacity(0.3)
                }
            }
            .cornerRadius(12)
            .simultaneousGesture(TapGesture().onEnded { _ in
                if let url = message.appleMapsURL, UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }, including: message.isVideo ? .subviews : .all)
            .contextMenu {
                MessageActionMenu()
                    .environmentObject(viewModel)
            }
            .onAppear {
                viewModel.calculate()
            }

            if !message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }

            if isMe {
                selectRadio
            }
        }
        .onChange(of: threadVM?.selectedMessages.contains(where: { $0.id == message.id }) == true) { newValue in
            isSelected = newValue
        }
    }

    var selectRadio: some View {
        Image(systemName: isSelected ? "checkmark.circle" : "circle")
            .font(.title)
            .frame(width: viewModel.isInSelectMode ? 22 : 0.001, height: viewModel.isInSelectMode ? 22 : 0.001, alignment: .center)
            .foregroundColor(Color.blue)
            .padding(viewModel.isInSelectMode ? 24 : 0.001)
            .scaleEffect(x: viewModel.isInSelectMode ? 1.0 : 0.001, y: viewModel.isInSelectMode ? 1.0 : 0.001, anchor: .center)
            .onTapGesture {
                withAnimation {
                    isSelected.toggle()
                }
                threadVM?.toggleSelectedMessage(message, isSelected)
            }
    }
}
