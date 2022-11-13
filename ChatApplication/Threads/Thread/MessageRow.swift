//
//  MessageRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

protocol MessageViewModelProtocol {
    var message: Message { get set }
    var messageId: Int { get }
    var isMe: Bool { get }
    var type: MessageType? { get }
    var isTextMessageType: Bool { get }
    var isUploadMessage: Bool { get }
    var isFileType: Bool { get }
    func togglePin()
    func pin()
    func unpin()
}

class MessageViewModel: ObservableObject, MessageViewModelProtocol {
    @Published
    var message: Message

    var currentUser: User? { Chat.sharedInstance.userInfo ?? AppState.shared.user }

    var isMe: Bool { message.ownerId ?? 0 == currentUser?.id ?? 0 }

    var type: MessageType? { message.messageType ?? .unknown }

    var isTextMessageType: Bool { type == .text || isFileType }

    var isFileType: Bool { type == .podSpacePicture || type == .picture || type == .podSpaceFile || type == .file }

    var isUploadMessage: Bool { message is UploadFileMessage }

    var messageId: Int { message.id ?? 0 }

    init(message: Message) {
        self.message = message
    }

    func togglePin() {
        if message.pinned == false {
            pin()
        } else {
            unpin()
        }
    }

    func pin() {
        Chat.sharedInstance.pinMessage(.init(messageId: messageId)) { messageId, _, error in
            if error == nil, messageId != nil {
                self.message.pinned = true
            }
        }
    }

    func unpin() {
        Chat.sharedInstance.unpinMessage(.init(messageId: messageId)) { messageId, _, error in
            if error == nil, messageId != nil {
                self.message.pinned = false
            }
        }
    }
}

struct MessageRow: View {
    @ObservedObject
    var viewModel: MessageViewModel

    @ObservedObject
    var threadViewModel: ThreadViewModel

    @State
    private(set) var showParticipants: Bool = false

    @Binding
    var isInEditMode: Bool

    @State
    private var isSelected = false

    var proxy: GeometryProxy

    init(viewModel: MessageViewModel, threadViewModel: ThreadViewModel, isInEditMode: Binding<Bool>, isMeForPreView: Bool? = nil, proxy: GeometryProxy) {
        self.viewModel = viewModel
        self._isInEditMode = isInEditMode
        self.proxy = proxy
        self.threadViewModel = threadViewModel
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
                    TextMessageType(proxy: proxy)
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

    var proxy: GeometryProxy

    var body: some View {
        HStack {
            if viewModel.isMe {
                Spacer()
            }
            let calculatedSize = message.calculatedMaxAndMinWidth(proxy: proxy)
            VStack {
                if let forwardInfo = message.forwardInfo {
                    ForwardMessageRow(forwardInfo: forwardInfo)
                }

                if viewModel.isFileType {
                    DownloadFileView(message: message)
                }

                // TODO: TEXT must be alignment and image muset be fit
                Text(((message.message?.isEmpty ?? true) == true ? message.metaData?.name : message.message) ?? "")
                    .multilineTextAlignment(message.message?.isEnglishString == true ? .leading : .trailing)
                    .padding(.top, 8)
                    .padding([.leading, .trailing, .top])
                    .font(Font(UIFont.systemFont(ofSize: 18)))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)

                MessageFooterView(viewModel: viewModel)
                    .padding(.bottom, 8)
                    .padding([.leading, .trailing])
            }
            .frame(minWidth: calculatedSize.minWidth, maxWidth: calculatedSize.maxWidth, minHeight: 48, alignment: .leading)
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

                if viewModel.message.isFileType == true {
                    Button {
                        threadViewModel.clearCacheFile(message: message)
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
            }

            if !viewModel.isMe {
                Spacer()
            }
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

    var message: Message {viewModel.message}

    var body: some View {
        HStack {
            if let fileSize = message.metaData?.file?.size, let size = Int(fileSize) {
                Text(size.toSizeString)
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                    .foregroundColor(Color(named: "dark_green").opacity(0.8))
            }
            Spacer()
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
        }
        .padding([.top], 4)
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { proxy in
            List {
                let threadVM = ThreadViewModel(thread: MockData.thread)
                MessageRow(viewModel: .init(message: MockData.message), threadViewModel: threadVM, isInEditMode: .constant(true), isMeForPreView: false, proxy: proxy)
                MessageRow(viewModel: .init(message: MockData.message), threadViewModel: threadVM, isInEditMode: .constant(true), isMeForPreView: true, proxy: proxy)
                MessageRow(viewModel: .init(message: MockData.uploadMessage), threadViewModel: threadVM, isInEditMode: .constant(true), proxy: proxy)
            }
            .listStyle(.plain)
        }
    }
}
