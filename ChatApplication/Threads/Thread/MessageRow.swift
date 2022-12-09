//
//  MessageRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct MessageRow: View {
    @ObservedObject var viewModel: MessageViewModel

    @EnvironmentObject var threadViewModel: ThreadViewModel

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
                        threadViewModel.toggleSelectedMessage(viewModel.message, isSelected)
                    }
            }
            if let type = viewModel.message.type {
                if viewModel.message.isUploadMessage {
                    UploadMessageType()
                        .environmentObject(viewModel)
                        .environmentObject(threadViewModel)
                } else if viewModel.message.isTextMessageType || viewModel.message.isUnsentMessage {
                    if viewModel.message.isMe {
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
    @EnvironmentObject var viewModel: MessageViewModel

    @EnvironmentObject var threadViewModel: ThreadViewModel

    @Environment(\.colorScheme) var colorScheme

    var message: Message { viewModel.message }

    var body: some View {
        HStack(alignment: .center) {
            if let time = message.time, let date = Date(milliseconds: Int64(time)) {
                Text("Call \(viewModel.message.type == .endCall ? "ended" : "started") at \(date.timeAgoSinceDate())")
                    .foregroundColor(Color.primary.opacity(0.8))
                    .font(.subheadline)
                    .padding(2)
            }

            Image(systemName: viewModel.message.type == .startCall ? "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(viewModel.message.type == .startCall ? Color.green : Color.red)
        }
        .padding([.leading, .trailing])
        .background(colorScheme == .light ? Color(CGColor(red: 0.718, green: 0.718, blue: 0.718, alpha: 0.8)) : Color.gray.opacity(0.1))
        .cornerRadius(6)
        .frame(maxWidth: .infinity)
    }
}

struct TextMessageType: View {
    @EnvironmentObject var viewModel: MessageViewModel

    @EnvironmentObject var threadViewModel: ThreadViewModel

    var message: Message { viewModel.message }

    var body: some View {
        HStack(spacing: 8) {
            if viewModel.message.isMe {
                Spacer()
            }
            if !viewModel.message.isMe {
                sameUserAvatar
            }
            VStack {
                if let forwardInfo = message.forwardInfo {
                    ForwardMessageRow(forwardInfo: forwardInfo)
                }

                if viewModel.message.isFileType {
                    DownloadFileView(message: message)
                        .frame(maxHeight: 320)
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
                            threadViewModel.resendUnsetMessage(message)
                        }

                        Button("Cancel".uppercased(), role: .destructive) {
                            threadViewModel.cancelUnsentMessage(message.uniqueId ?? "")
                        }
                    }
                    .padding()
                    .font(.caption.bold())
                }

                MessageFooterView(viewModel: viewModel)
                    .padding(.bottom, 8)
                    .padding([.leading, .trailing])
            }
            .frame(maxWidth: message.calculatedMaxAndMinWidth, alignment: .leading)
            .padding([.leading, .trailing], 0)
            .contentShape(Rectangle())
            .background(viewModel.message.isMe ? Color(UIColor(named: "chat_me")!) : Color(UIColor(named: "chat_sender")!))
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
                        threadViewModel.replyMessage = message
                    }
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                Button {
                    withAnimation {
                        threadViewModel.forwardMessage = message
                    }
                } label: {
                    Label("forward", systemImage: "arrowshape.turn.up.forward")
                }

                Button {
                    withAnimation {
                        threadViewModel.editMessage = message
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
                        threadViewModel.isInEditMode = true
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

            if viewModel.message.isMe {
                sameUserAvatar
            }

            if !viewModel.message.isMe {
                Spacer()
            }
        }
    }

    @ViewBuilder var sameUserAvatar: some View {
        if !threadViewModel.isSameUser(message: message), message.participant != nil {
            viewModel.imageLoader.imageView
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(18)
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
    @EnvironmentObject var viewModel: MessageViewModel

    @EnvironmentObject var threadViewModel: ThreadViewModel

    var message: Message { viewModel.message }

    var body: some View {
        HStack(alignment: .top) {
            Spacer()
            VStack(spacing: 8) {
                if message.isUnsentMessage == false {
                    UploadFileView(message: message)
                        .environmentObject(threadViewModel)
                        .environmentObject(UploadFileViewModel(message: message, thread: threadViewModel.thread))
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
                            .foregroundColor(Color(named: "icon_color").opacity(0.8))
                    }
                }

                if let fileName = message.fileName {
                    Text("\(fileName)\(message.fileExtension ?? "")")
                        .foregroundColor(Color(named: "dark_green").opacity(0.8))
                        .font(.caption)
                }

                if let message = message.messageTitle {
                    Text(message)
                        .foregroundColor(.black)
                        .font(Font(UIFont.systemFont(ofSize: 18)))
                }

                if message.isUnsentMessage {
                    HStack {
                        Spacer()
                        Button("Resend".uppercased()) {
                            threadViewModel.resendUnsetMessage(message)
                        }

                        Button("Cancel".uppercased(), role: .destructive) {
                            threadViewModel.cancelUnsentMessage(message.uniqueId ?? "")
                        }
                    }
                    .padding([.leading, .trailing])
                    .font(.caption.bold())
                }
            }
            .frame(maxWidth: message.isImage ? 320 : 164)
            .padding()
            .contentShape(Rectangle())
            .background(Color(UIColor(named: "chat_me")!))
            .cornerRadius(12)
        }
        .padding(.trailing, 42)
    }
}

struct MessageFooterView: View {
    var viewModel: MessageViewModel
    var message: Message { viewModel.message }
    static let clockImage = UIImage(named: "clock")
    static let sentImage = UIImage(named: "single_chekmark")
    static let seenImage = UIImage(named: "double_checkmark")

    @ViewBuilder var image: some View {
        if message.seen == true {
            Image(uiImage: MessageFooterView.seenImage!)
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(Color(named: "dark_green").opacity(0.8))
                .font(.subheadline)
        } else if message.delivered == true {
            Image(uiImage: MessageFooterView.seenImage!)
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.gray)
                .font(.subheadline)
        } else if message.id != nil {
            Image(uiImage: MessageFooterView.sentImage!)
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(Color(named: "dark_green").opacity(0.8))
                .font(.subheadline)
        } else {
            Image(uiImage: MessageFooterView.clockImage!)
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(Color(named: "dark_green").opacity(0.8))
                .font(.subheadline)
        }
    }

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

                    if viewModel.message.isMe {
                        image
                    }
                }
                if viewModel.message.edited == true {
                    Text("Edited")
                        .foregroundColor(Color(named: "dark_green").opacity(0.8))
                        .font(.caption2)
                }
            }
        }
        .animation(.easeInOut, value: message.delivered)
        .animation(.easeInOut, value: message.seen)
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
