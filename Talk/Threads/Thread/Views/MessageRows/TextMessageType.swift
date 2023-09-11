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

struct TextMessageType: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    let viewModel: MessageRowViewModel
    @State var isInSelectionMode = false

    var body: some View {
        HStack(spacing: 8) {
            if !viewModel.isMe {
                SelectMessageRadio(isInSelectionMode: isInSelectionMode)
            }

            if message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }

            MutableMessageView()

            if !message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }

            if viewModel.isMe {
                SelectMessageRadio(isInSelectionMode: isInSelectionMode)
            }
        }
        .environmentObject(viewModel)
        .onReceive(viewModel.objectWillChange) { _ in
            if viewModel.isInSelectMode != isInSelectionMode {
                withAnimation {
                    isInSelectionMode = viewModel.isInSelectMode
                }
            }
        }
    }
}

struct SelectMessageRadio: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    let isInSelectionMode: Bool

    var body: some View {
        ZStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .scaleEffect(x: viewModel.isSelected ? 1 : 0.001, y: viewModel.isSelected ? 1 : 0.001, anchor: .center)
                .foregroundColor(Color.blue)

            Image(systemName: "circle")
                .font(.title)
                .foregroundColor(Color.blue)
        }
        .frame(width: isInSelectionMode ? 22 : 0.001, height: isInSelectionMode ? 22 : 0.001, alignment: .center)
        .padding(isInSelectionMode ? 24 : 0.001)
        .scaleEffect(x: isInSelectionMode ? 1.0 : 0.001, y: isInSelectionMode ? 1.0 : 0.001, anchor: .center)
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
            ZStack(alignment: .topLeading) {
                if message.isFileType, message.id ?? 0 > 0, let downloadVM = viewModel.downloadFileVM {
                    DownloadFileView(viewModel: downloadVM)
                        .frame(maxHeight: 320)
                }
                VStack {
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
                    AvatarView(message: message, viewModel: threadVM)
                }
            }
            .clipped()

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
        .background(message.isMe(currentUserId: AppState.shared.user?.id) ? Color.chatMeBg : Color.chatSenderBg)
        .overlay {
            if viewModel.isHighlited {
                Color.blue.opacity(0.3)
            }
        }
        .cornerRadius(18)
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
        var viewModel: MessageRowViewModel {
            let participant = Participant(id: 0, name: "John Doe")
            return MessageRowViewModel(
                message: .init(
                    id: 1,
                    message: "TEST",
                    seen: true,
                    time: UInt(Date().millisecondsSince1970),
                    participant: participant
                ), viewModel: .init(thread: .init(id: 1))
            )
        }

        var body: some View {
            TextMessageType(viewModel: viewModel)
                .environmentObject(viewModel)
                .environmentObject(NavigationModel())
        }
    }

    static var previews: some View {
        Preview()
    }
}
