//
//  MessageRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct MessageRow: View {
    @ObservedObject
    var viewModel: MessageViewModel

    @EnvironmentObject
    var threadViewModel: ThreadViewModel

    @State
    private(set) var showParticipants: Bool = false

    @Binding
    var isInEditMode: Bool

    @State
    private var isSelected = false

    init(viewModel: MessageViewModel, isInEditMode: Binding<Bool>) {
        self.viewModel = viewModel
        self._isInEditMode = isInEditMode
    }

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
                        threadViewModel.toggleSelectedMessage(viewModel.message, isSelected)
                    }
            }
            if let type = viewModel.type {
                if viewModel.isUploadMessage {
                    UploadMessageType()
                        .environmentObject(viewModel)
                        .environmentObject(threadViewModel)
                } else if viewModel.isTextMessageType {
                    if viewModel.isMe {
                        Spacer()
                    }
                    TextMessageType()
                        .environmentObject(viewModel)
                        .environmentObject(threadViewModel)
                } else if type == .endCall || type == .startCall {
                    CallMessageType()
                        .environmentObject(viewModel)
                        .environmentObject(threadViewModel)
                }
            }
        }
    }
}

struct CallMessageType: View {
    @EnvironmentObject
    var viewModel: MessageViewModel

    @EnvironmentObject
    var threadViewModel: ThreadViewModel

    @Environment(\.colorScheme)
    var colorScheme

    var message: Message { viewModel.message }

    var body: some View {
        HStack(alignment: .center) {
            if let time = message.time, let date = Date(milliseconds: Int64(time)) {
                Text("Call \(viewModel.type == .endCall ? "ended" : "started") at \(date.timeAgoSinceDate())")
                    .foregroundColor(Color.primary.opacity(0.8))
                    .font(.subheadline)
                    .padding(2)
            }

            Image(systemName: viewModel.type == .startCall ? "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(viewModel.type == .startCall ? Color.green : Color.red)
        }
        .padding([.leading, .trailing])
        .background(colorScheme == .light ? Color(CGColor(red: 0.718, green: 0.718, blue: 0.718, alpha: 0.8)) : Color.gray.opacity(0.1))
        .cornerRadius(6)
        .frame(maxWidth: .infinity)
    }
}

struct TextMessageType: View {
    @EnvironmentObject
    var viewModel: MessageViewModel

    @EnvironmentObject
    var threadViewModel: ThreadViewModel

    var message: Message { viewModel.message }

    var isSameUser: Bool {
        if let previousMessage = threadViewModel.messages.first(where: { $0.id == message.previousId }) {
            return previousMessage.participant?.id ?? 0 == message.participant?.id ?? -1
        }
        return false
    }

    var body: some View {
        HStack(spacing: 8) {
            if viewModel.isMe {
                Spacer()
            }
            if !viewModel.isMe {
                SameUserAvatar
            }
            VStack {
                if let forwardInfo = message.forwardInfo {
                    ForwardMessageRow(forwardInfo: forwardInfo)
                }

                if viewModel.isFileType {
                    DownloadFileView(message: message)
                        .frame(maxHeight: 320)
                }

                // TODO: TEXT must be alignment and image muset be fit
                Text(message.messageTitle)
                    .multilineTextAlignment(message.message?.isEnglishString == true ? .leading : .trailing)
                    .padding(.top, 8)
                    .padding([.leading, .trailing, .top])
                    .font(Font(UIFont.systemFont(ofSize: 18)))
                    .foregroundColor(.black)

                MessageFooterView(viewModel: viewModel)
                    .padding(.bottom, 8)
                    .padding([.leading, .trailing])
            }
            .frame(maxWidth: message.calculatedMaxAndMinWidth, alignment: .leading)
            .padding([.leading, .trailing], 0)
            .contentShape(Rectangle())
            .background(viewModel.isMe ? Color(UIColor(named: "chat_me")!) : Color(UIColor(named: "chat_sender")!))
            .cornerRadius(12)
            .onTapGesture {
                print("on tap gesture")
            }
            .onLongPressGesture {
                print("long press triggred")
            }
            .contextMenu {
                Button {
                    withAnimation {
                        threadViewModel.setReplyMessage(message)
                    }
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                Button {
                    withAnimation {
                        threadViewModel.setForwardMessage(message)
                    }
                } label: {
                    Label("forward", systemImage: "arrowshape.turn.up.forward")
                }

                Button {
                    withAnimation {
                        threadViewModel.setEditMessage(message)
                    }
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                .disabled(viewModel.message.editable == false)

                if viewModel.message.isFileType == true {
                    Button {
                        viewModel.clearCacheFile(message: message)
                    } label: {
                        Label("Delete file from cache", systemImage: "cylinder.split.1x2")
                    }
                }

                Button {
                    viewModel.togglePin()
                } label: {
                    Label((message.pinned ?? false) ? "UnPin" : "Pin", systemImage: "pin")
                }

                Button {
                    withAnimation {
                        threadViewModel.setIsInEditMode(true)
                    }
                } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }

                Button(role: .destructive) {
                    withAnimation {
                        threadViewModel.deleteMessages([viewModel.message])
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(viewModel.message.deletable == false)
            }

            if viewModel.isMe {
                SameUserAvatar
            }

            if !viewModel.isMe {
                Spacer()
            }
        }
    }

    @ViewBuilder
    var SameUserAvatar: some View {
        if !isSameUser, let participant = message.participant {
            let token = EnvironmentValues().isPreview ? "FAKE_TOKEN" : TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken
            Avatar(
                url: participant.image,
                userName: participant.username?.uppercased(),
                style: .init(size: 36, textSize: 12),
                token: token
            )
        } else {
            Rectangle()
                .frame(width: 36, height: 36)
                .hidden()
        }
    }
}

struct ForwardMessageRow: View {
    var forwardInfo: ForwardInfo

    @State
    var showReadOnlyThreadView: Bool = false

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
                NavigationLink(destination: ThreadView(viewModel: ThreadViewModel(thread: forwardThread, readOnly: true)), isActive: $showReadOnlyThreadView) {
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
    @EnvironmentObject
    var viewModel: MessageViewModel

    @EnvironmentObject
    var threadViewModel: ThreadViewModel

    var message: UploadFileMessage { viewModel.message as! UploadFileMessage }

    var body: some View {
        HStack(alignment: .top) {
            Spacer()
            VStack {
                UploadFileView(threadViewModel, message: message)
                    .frame(width: 148, height: 148)
                if let fileName = message.metaData?.name {
                    Text(fileName)
                        .foregroundColor(.black)
                        .font(Font(UIFont.systemFont(ofSize: 18)))
                }

                if let message = message.message {
                    Text(message)
                        .foregroundColor(.black)
                        .font(Font(UIFont.systemFont(ofSize: 18)))
                }
            }
            .padding()
            .contentShape(Rectangle())
            .background(Color(UIColor(named: "chat_me")!))
            .cornerRadius(12)
        }
    }
}

struct MessageFooterView: View {
    var viewModel: MessageViewModel

    var message: Message { viewModel.message }

    var body: some View {
        HStack {
            if let fileSize = message.metaData?.file?.size, let size = Int(fileSize) {
                Text(size.toSizeString)
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                    .foregroundColor(Color(named: "dark_green").opacity(0.8))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                HStack {
                    if let time = message.time, let date = Date(timeIntervalSince1970: TimeInterval(time) / 1000) {
                        Text("\(date.getTime())")
                            .foregroundColor(Color(named: "dark_green").opacity(0.8))
                            .font(.subheadline)
                    }

                    if viewModel.isMe {
                        Image(uiImage: UIImage(named: message.seen == true ? "double_checkmark" : "single_chekmark")!)
                            .resizable()
                            .frame(width: 14, height: 14)
                            .foregroundColor(Color(named: "dark_green").opacity(0.8))
                            .font(.subheadline)
                    }
                }
                if viewModel.message.edited == true {
                    Text("Edited")
                        .foregroundColor(Color(named: "dark_green").opacity(0.8))
                        .font(.caption2)
                }
            }
        }
        .padding([.top], 4)
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            let threadVM = ThreadViewModel(thread: MockData.thread)
            MessageRow(viewModel: .init(message: MockData.message), isInEditMode: .constant(true))
                .environmentObject(threadVM)
            MessageRow(viewModel: .init(message: MockData.message), isInEditMode: .constant(true))
                .environmentObject(threadVM)
            MessageRow(viewModel: .init(message: MockData.uploadMessage), isInEditMode: .constant(true))
                .environmentObject(threadVM)

            ForEach(MockData.generateMessages(count: 5), id: \.self) { message in
                TextMessageType()
                    .environmentObject(threadVM)
                    .environmentObject(MessageViewModel(message: message))
            }
        }
        .listStyle(.plain)
    }
}
