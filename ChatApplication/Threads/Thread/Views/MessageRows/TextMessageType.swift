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
    var message: Message
    @EnvironmentObject var calculation: MessageRowCalculationViewModel
    @EnvironmentObject var viewModel: ThreadViewModel
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
                AvatarView(message: message)
                if message.replyInfo != nil {
                    ReplyInfoMessageRow(message: message)
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
                        .environmentObject(calculation.downloadFileVM)
                        .frame(maxHeight: 320)
                }

                if let fileName = message.fileName {
                    Text("\(fileName)\(message.fileExtension ?? "")")
                        .foregroundColor(.darkGreen.opacity(0.8))
                        .font(.caption)
                }

                // TODO: TEXT must be alignment and image must be fit
                Text(calculation.markdownTitle)
                    .multilineTextAlignment(calculation.isEnglish ? .leading : .trailing)
                    .padding(8)
                    .font(.iransansBody)
                    .foregroundColor(.black)

                if let addressDetail = calculation.addressDetail {
                    Text(addressDetail)
                        .foregroundColor(.darkGreen.opacity(0.8))
                        .font(.caption)
                        .padding([.leading, .trailing])
                }

                if message.isUnsentMessage {
                    HStack {
                        Spacer()
                        Button("Resend".uppercased()) {
                            viewModel.resendUnsetMessage(message)
                        }

                        Button("Cancel".uppercased(), role: .destructive) {
                            viewModel.cancelUnsentMessage(message.uniqueId ?? "")
                        }
                    }
                    .padding()
                    .font(.caption.bold())
                }

                MessageFooterView(message: message)
                    .padding(.bottom, 8)
                    .padding([.leading, .trailing])
            }
            .frame(maxWidth: calculation.widthOfRow, alignment: .leading)
            .padding([.leading, .trailing], 0)
            .contentShape(Rectangle())
            .background(message.isMe(currentUserId: AppState.shared.user?.id) ? Color.chatMeBg : Color.chatSenderBg)
            .overlay {
                if viewModel.highliteMessageId == message.id {
                    Color.blue.opacity(0.3)
                }
            }
            .cornerRadius(12)
            .onTapGesture {
                if let url = message.appleMapsURL, UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            .contextMenu {
                MessageActionMenu(message: message)
            }
            .onAppear {
                calculation.calculate(message: message)
            }

            if !message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }

            if isMe {
                selectRadio
            }
        }
        .onChange(of: viewModel.selectedMessages.contains(where: { $0.id == message.id })) { newValue in
            isSelected = newValue
        }
    }

    var selectRadio: some View {
        Image(systemName: isSelected ? "checkmark.circle" : "circle")
            .font(.title)
            .frame(width: viewModel.isInEditMode ? 22 : 0.001, height: viewModel.isInEditMode ? 22 : 0.001, alignment: .center)
            .foregroundColor(Color.blue)
            .padding(viewModel.isInEditMode ? 24 : 0.001)
            .scaleEffect(x: viewModel.isInEditMode ? 1.0 : 0.001, y: viewModel.isInEditMode ? 1.0 : 0.001, anchor: .center)
            .onTapGesture {
                withAnimation {
                    isSelected.toggle()
                }
                viewModel.toggleSelectedMessage(message, isSelected)
            }
    }
}
