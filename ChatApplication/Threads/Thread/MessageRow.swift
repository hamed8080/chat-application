//
//  MessageRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct MessageRow: View {
    var message: Message
    @EnvironmentObject var viewModel: ThreadViewModel
    @State private(set) var showParticipants: Bool = false
    @Binding var isInEditMode: Bool
    @State private var isSelected = false

    var body: some View {
        HStack {
            if isInEditMode {
                Image(systemName: isSelected ? "checkmark.circle" : "circle")
                    .font(.title)
                    .frame(width: 22, height: 22, alignment: .center)
                    .foregroundColor(Color.blue)
                    .padding(24)
                    .onTapGesture {
                        isSelected.toggle()
                        viewModel.toggleSelectedMessage(message, isSelected)
                    }
            }
            if let type = message.type {
                if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                    if message.isMe {
                        Spacer()
                    }
                    TextMessageType(message: message)
                } else if type == .participantJoin || type == .participantLeft {
                    ParticipantMessageType(message: message)
                } else if type == .endCall || type == .startCall {
                    CallMessageType(message: message)
                }
            }
        }
    }
}

struct CallMessageType: View {
    var message: Message
    @EnvironmentObject var threadViewModel: ThreadViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center) {
            if let time = message.time, let date = Date(milliseconds: Int64(time)) {
                Text("Call \(message.type == .endCall ? "ended" : "started") at \(date.timeAgoSinceDate ?? "")")
                    .foregroundColor(Color.primary.opacity(0.8))
                    .font(.subheadline)
                    .padding(2)
            }

            Image(systemName: message.type == .startCall ? "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(message.type == .startCall ? Color.green : Color.red)
        }
        .padding([.leading, .trailing])
        .background(colorScheme == .light ? Color(CGColor(red: 0.718, green: 0.718, blue: 0.718, alpha: 0.8)) : Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

struct ParticipantMessageType: View {
    var message: Message
    @EnvironmentObject var threadViewModel: ThreadViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            let date = Date(milliseconds: Int64(message.time ?? 0)).timeAgoSinceDate ?? ""
            let name = message.participant?.name ?? ""
            let markdownText = try! AttributedString(markdown: "\(name) - \(date)")
            Text(markdownText)
                .foregroundColor(Color.primary.opacity(0.8))
                .font(.subheadline)
                .padding(2)

            Image(systemName: message.iconName)
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(message.type == .participantJoin ? Color.green : Color.red)
                .padding([.leading, .trailing], 6)
                .scaledToFit()
        }
        .padding([.leading, .trailing])
        .background(colorScheme == .light ? Color(CGColor(red: 0.718, green: 0.718, blue: 0.718, alpha: 0.8)) : Color.gray.opacity(0.1))
        .cornerRadius(6)
        .frame(maxWidth: .infinity)
    }
}

struct TextMessageType: View {
    var message: Message
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        HStack(spacing: 8) {
            if message.isMe {
                Spacer()
            }
            if !message.isMe {
                sameUserAvatar
            }
            VStack {
                if let forwardInfo = message.forwardInfo {
                    ForwardMessageRow(forwardInfo: forwardInfo)
                }

                if message.isUploadMessage {
                    UploadMessageType(message: message)
                        .frame(maxHeight: 320)
                }

                if message.isFileType, message.id ?? 0 > 0 {
                    DownloadFileView(message: message)
                        .frame(maxHeight: 320)
                }

                if let fileName = message.fileName {
                    Text("\(fileName)\(message.fileExtension ?? "")")
                        .foregroundColor(.darkGreen.opacity(0.8))
                        .font(.caption)
                }

                // TODO: TEXT must be alignment and image muset be fit
                Text(message.markdownTitle)
                    .multilineTextAlignment(message.message?.isEnglishString == true ? .leading : .trailing)
                    .padding(.top, 8)
                    .padding([.leading, .trailing, .top])
                    .font(Font(UIFont.systemFont(ofSize: 18)))
                    .foregroundColor(.black)

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
            .frame(maxWidth: message.calculatedMaxAndMinWidth, alignment: .leading)
            .padding([.leading, .trailing], 0)
            .contentShape(Rectangle())
            .background(message.isMe ? Color.chatMeBg : Color.chatSenderBg)
            .cornerRadius(12)
            .animation(.easeInOut, value: message.isUnsentMessage)
            .onTapGesture {
                print("on tap gesture")
            }
            .onLongPressGesture {
                print("long press triggred")
            }
            .contextMenu {
                Button {
                    withAnimation {
                        viewModel.replyMessage = message
                    }
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                Button {
                    withAnimation {
                        viewModel.forwardMessage = message
                    }
                } label: {
                    Label("forward", systemImage: "arrowshape.turn.up.forward")
                }

                Button {
                    withAnimation {
                        viewModel.editMessage = message
                    }
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                .disabled(message.editable == false)

                Button {
                    UIPasteboard.general.string = message.message
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                if message.isFileType == true {
                    Button {
                        viewModel.clearCacheFile(message: message)
                    } label: {
                        Label("Delete file from cache", systemImage: "cylinder.split.1x2")
                    }
                }

                Button {
                    viewModel.togglePinMessage(message)
                } label: {
                    Label((message.pinned ?? false) ? "UnPin" : "Pin", systemImage: "pin")
                }

                Button {
                    withAnimation {
                        viewModel.isInEditMode = true
                    }
                } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }

                Button(role: .destructive) {
                    withAnimation {
                        viewModel.deleteMessages([message])
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(message.deletable == false)
            }

            if message.isMe {
                sameUserAvatar
            }

            if !message.isMe {
                Spacer()
            }
        }
    }

    @ViewBuilder var sameUserAvatar: some View {
        if !viewModel.isSameUser(message: message), message.participant != nil {
            NavigationLink {
                DetailView(viewModel: DetailViewModel(user: message.participant))
            } label: {
                ImageLaoderView(url: message.participant?.image, userName: message.participant?.name ?? message.participant?.username)
                    .font(.system(size: 16).weight(.heavy))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(18)
            }
        } else {
            Rectangle()
                .frame(width: 36, height: 36)
                .hidden()
        }
    }
}

struct ForwardMessageRow: View {
    var forwardInfo: ForwardInfo
    @State var showReadOnlyThreadView: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let name = forwardInfo.participant?.name {
                    Text(name)
                        .italic()
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                }
                Spacer()
                Image(systemName: "arrowshape.turn.up.right")
                    .foregroundColor(Color.blue)
            }
            .padding([.leading, .trailing, .top], 8)
            .frame(minHeight: 20)
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding([.top], 4)
            if let forwardThread = forwardInfo.conversation {
                NavigationLink(destination: ThreadView(thread: forwardThread), isActive: $showReadOnlyThreadView) {
                    EmptyView()
                }
                .frame(width: 0)
                .hidden()
            }
        }.onTapGesture {
            showReadOnlyThreadView = true
        }
    }
}

struct UploadMessageType: View {
    var message: Message
    @EnvironmentObject var threadViewModel: ThreadViewModel

    var body: some View {
        VStack(spacing: 8) {
            if message.isUnsentMessage == false {
                UploadFileView(message: message)
                    .environmentObject(threadViewModel)
            } else if let data = message.uploadFile?.uploadFileRequest.data {
                // Show cache version image if the sent was failed.
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320)
                } else if let iconName = message.iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .scaledToFit()
                        .padding()
                        .foregroundColor(.iconColor.opacity(0.8))
                }
            }
        }
    }
}

struct MessageFooterView: View {
    var message: Message
    // We never use this viewModel but it will refresh view when a event on this message happened such as onSent, onDeliver,onSeen.
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        HStack {
            if let fileSize = message.metaData?.file?.size, let size = Int(fileSize) {
                Text(size.toSizeString)
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                    .foregroundColor(.darkGreen.opacity(0.8))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                HStack {
                    Text(message.formattedTimeString ?? "")
                        .foregroundColor(.darkGreen.opacity(0.8))
                        .font(.system(size: 12, design: .rounded))
                    if message.isMe {
                        Image(uiImage: message.footerStatus.image)
                            .resizable()
                            .frame(width: 14, height: 14)
                            .foregroundColor(message.footerStatus.fgColor)
                            .font(.subheadline)
                    }
                }
                if message.edited == true {
                    Text("Edited")
                        .foregroundColor(.darkGreen.opacity(0.8))
                        .font(.caption2)
                }
            }
        }
        .animation(.easeInOut, value: message.delivered)
        .animation(.easeInOut, value: message.seen)
        .animation(.easeInOut, value: message.edited)
        .padding([.top], 4)
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        let threadVM = ThreadViewModel()
        List {
            MessageRow(message: MockData.message, isInEditMode: .constant(true))
                .environmentObject(threadVM)
            MessageRow(message: MockData.message, isInEditMode: .constant(true))
                .environmentObject(threadVM)
            MessageRow(message: MockData.message, isInEditMode: .constant(true))
                .environmentObject(threadVM)

            ForEach(MockData.generateMessages(count: 5)) { _ in
                TextMessageType(message: MockData.message)
                    .environmentObject(threadVM)
            }
        }
        .onAppear {
            threadVM.setup(thread: MockData.thread)
        }
        .listStyle(.plain)
    }
}
