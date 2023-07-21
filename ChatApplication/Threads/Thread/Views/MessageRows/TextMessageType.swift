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
    let viewModel: MessageRowViewModel
    @State private var isSelected = false
    @State var isInSelectionMode = false

    var body: some View {
        HStack(spacing: 8) {
            if !viewModel.isMe {
                selectRadio
            }

            if message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }

            MutableMessageView()
                .environmentObject(viewModel)

            if !message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }

            if viewModel.isMe {
                selectRadio
            }
        }
        .onReceive(viewModel.objectWillChange) { _ in
            if viewModel.isInSelectMode != isInSelectionMode {
                withAnimation {
                    isInSelectionMode = viewModel.isInSelectMode
                }
            }
        }
        .onChange(of: threadVM?.selectedMessages.contains(where: { $0.id == message.id }) == true) { newValue in
            withAnimation {
                isSelected = newValue
            }
        }
    }

    var selectRadio: some View {
        ZStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .scaleEffect(x: isSelected ? 1 : 0.001, y: isSelected ? 1 : 0.001, anchor: .center)
                .foregroundColor(Color.blue)

            Image(systemName: "circle")
                .font(.title)
                .foregroundColor(Color.blue)
        }
        .frame(width: isInSelectionMode ? 22 : 0.001, height: isInSelectionMode ? 22 : 0.001, alignment: .center)
        .padding(isInSelectionMode ? 24 : 0.001)
        .scaleEffect(x: isInSelectionMode ? 1.0 : 0.001, y: isInSelectionMode ? 1.0 : 0.001, anchor: .center)
        .onTapGesture {
            withAnimation(!isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
                isSelected.toggle()
            }
            threadVM?.toggleSelectedMessage(message, isSelected)
        }
    }
}

struct MutableMessageView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }

    var body: some View {
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
                DownloadFileView(viewModel: viewModel.downloadFileVM)
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
    }
}

struct TextMessageType_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            let participant = Participant(id: 0, name: "John Doe")
            TextMessageType(
                viewModel: MessageRowViewModel(
                    message: .init(
                        id: 1,
                        message: "TEST",
                        seen: true,
                        time: UInt(Date().millisecondsSince1970), participant: participant
                    ),
                    viewModel: .init(thread: Conversation(id: 1))
                )
            )
        }
    }

    static var previews: some View {
        Preview()
    }
}
