//
//  MessageRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MessageRow: View {
    var message: Message
    @State var calculation: MessageRowCalculationViewModel
    @EnvironmentObject var viewModel: ThreadViewModel
    @State private(set) var showParticipants: Bool = false
    @Binding var isInEditMode: Bool
    @State private var isSelected = false

    var body: some View {
        HStack {
            if let type = message.type {
                if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
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
                    if message.isMe(currentUserId: AppState.shared.user?.id) {
                        Spacer()
                    }
                    TextMessageType(message: message)
                        .environmentObject(calculation)
                } else if type == .participantJoin || type == .participantLeft {
                    ParticipantMessageType(message: message)
                } else if type == .endCall || type == .startCall {
                    CallMessageType(message: message)
                }
            }
        }
        .animation(.easeInOut, value: isInEditMode)
    }
}

struct CallMessageType: View {
    var message: Message
    @EnvironmentObject var threadViewModel: ThreadViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center) {
            if let time = message.time {
                let date = Date(milliseconds: Int64(time))
                Text("Call \(message.type == .endCall ? "ended" : "started") - \(date.timeAgoSinceDateCondense ?? "")")
                    .foregroundColor(Color.primary.opacity(0.8))
                    .font(.iransansSubheadline)
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
            let date = Date(milliseconds: Int64(message.time ?? 0)).timeAgoSinceDateCondense ?? ""
            let name = message.participant?.name ?? ""
            let markdownText = try! AttributedString(markdown: "\(name) - \(date)")
            Text(markdownText)
                .foregroundColor(Color.primary.opacity(0.8))
                .font(.iransansBoldCaption2)
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
    @EnvironmentObject var calculation: MessageRowCalculationViewModel
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        HStack(spacing: 8) {
            if message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }
            VStack(spacing: 0) {
                SameAvatar(message: message)
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
                        .frame(maxHeight: 320)
                }

                if let fileName = message.fileName {
                    Text("\(fileName)\(message.fileExtension ?? "")")
                        .foregroundColor(.darkGreen.opacity(0.8))
                        .font(.caption)
                }

                // TODO: TEXT must be alignment and image muset be fit
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
            .cornerRadius(12)
            .animation(.easeInOut, value: message.isUnsentMessage)
            .onTapGesture {
                if let url = message.appleMapsURL, UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
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
            .onAppear {
                calculation.calculate(message: message)
            }

            if !message.isMe(currentUserId: AppState.shared.user?.id) {
                Spacer()
            }
        }
    }
}

struct SameAvatar: View {
    var message: Message
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if !viewModel.isSameUser(message: message), message.participant != nil {
            NavigationLink {
                DetailView(viewModel: DetailViewModel(user: message.participant))
            } label: {
                HStack(spacing: 8) {
                    if message.isMe(currentUserId: AppState.shared.user?.id) {
                        Spacer()
                        Text("\(message.participant?.name ?? "")")
                            .font(.iransansBoldCaption)
                            .foregroundColor(.darkGreen)
                            .lineLimit(1)
                    }

                    ImageLaoderView(url: message.participant?.image, userName: message.participant?.name ?? message.participant?.username)
                        .id("\(message.participant?.image ?? "")\(message.participant?.id ?? 0)")
                        .font(.iransansSubheadline)
                        .foregroundColor(.white)
                        .frame(width: MessageRowCalculationViewModel.avatarSize, height: MessageRowCalculationViewModel.avatarSize)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(MessageRowCalculationViewModel.avatarSize / 2)
                    if !message.isMe(currentUserId: AppState.shared.user?.id) {
                        Text("\(message.participant?.name ?? "")")
                            .font(.iransansBoldCaption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                .padding(.bottom, 4)
                .padding([.leading, .trailing, .top])
            }
        } else {
            Rectangle()
                .frame(width: 36, height: 0)
                .hidden()
        }
    }
}

struct ReplyInfoMessageRow: View {
    var message: Message
    @EnvironmentObject var threadViewModel: ThreadViewModel
    @EnvironmentObject var calculation: MessageRowCalculationViewModel

    var body: some View {
        HStack {
            Image(systemName: "poweron")
                .resizable()
                .frame(width: 3)
                .frame(minHeight: 0, maxHeight: .infinity)
                .foregroundColor(.orange)
            VStack(spacing: 4) {
                if let name = message.replyInfo?.participant?.name {
                    Text("\(name)")
                        .font(.iransansBoldCaption2)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: name.isEnglishString ? .leading : .trailing)
                        .foregroundColor(.orange)
                        .padding([.leading, .trailing], 4)
                }

                if let message = message.replyInfo?.message {
                    Text(message)
                        .font(.iransansCaption3)
                        .padding([.leading, .trailing], 4)
                        .cornerRadius(8, corners: .allCorners)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: message.isEnglishString ? .leading : .trailing)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: calculation.widthOfRow - 32, height: 48)
        .background(Color.replyBg)
        .cornerRadius(8)
        .padding([.top, .leading, .trailing], 12)
        .truncationMode(.tail)
        .lineLimit(1)
        .onTapGesture {
            print("tap on move to reply to")
            threadViewModel.setScrollToUniqueId("uniqueId?")
        }
        .onAppear {
            calculation.calculate(message: message)
        }
    }
}

struct ForwardMessageRow: View {
    var forwardInfo: ForwardInfo
    @State var showReadOnlyThreadView: Bool = false

    @ViewBuilder var body: some View {
        if let forwardThread = forwardInfo.conversation {
            NavigationLink {
                ThreadView(thread: forwardThread)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        if let name = forwardInfo.participant?.name {
                            Text(name)
                                .italic()
                                .font(.iransansBoldCaption2)
                                .foregroundColor(Color.gray)
                        }
                        Spacer()
                        Image(systemName: "arrowshape.turn.up.right")
                            .foregroundColor(Color.blue)
                    }
                    .padding([.leading, .trailing, .top], 8)
                    .frame(minHeight: 36)
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding([.top], 4)
                }
            }
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
                } else {
                    let iconName = message.iconName
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
    @State var timeString: String = ""
    @EnvironmentObject var calculation: MessageRowCalculationViewModel

    var body: some View {
        HStack {
            if let fileSize = calculation.fileSizeString {
                Text(fileSize)
                    .multilineTextAlignment(.leading)
                    .font(.iransansBody)
                    .foregroundColor(.darkGreen.opacity(0.8))
            }
            Spacer()
            Text(calculation.timeString)
                .foregroundColor(.darkGreen.opacity(0.8))
                .font(.iransansBoldCaption2)
            if message.isMe(currentUserId: AppState.shared.user?.id) {
                Image(uiImage: message.footerStatus.image)
                    .resizable()
                    .frame(width: 14, height: 14)
                    .foregroundColor(message.footerStatus.fgColor)
                    .font(.subheadline)
            }

            if message.edited == true {
                Text("Edited")
                    .foregroundColor(.darkGreen.opacity(0.8))
                    .font(.caption2)
            }
        }
        .animation(.easeInOut, value: message.delivered)
        .animation(.easeInOut, value: message.seen)
        .animation(.easeInOut, value: message.edited)
        .padding(.top, 4)
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        let threadVM = ThreadViewModel()
        List {
            ForEach(MockData.generateMessages(count: 5)) { message in
                MessageRow(message: message, calculation: .init(), isInEditMode: .constant(false))
                    .environmentObject(threadVM)
            }
        }
        .environmentObject(MessageRowCalculationViewModel())
        .onAppear {
            threadVM.setup(thread: MockData.thread)
        }
        .listStyle(.plain)
    }
}

struct ReplyInfo_Previews: PreviewProvider {
    static let participant = Participant(name: "john", username: "john_9090")
    static let replyInfo = ReplyInfo(repliedToMessageId: 0, message: "Hi how are you?", messageType: .text, time: 100, participant: participant)
    static let isMEParticipant = Participant(name: "Sam", username: "sam_rage")
    static let isMeReplyInfo = ReplyInfo(repliedToMessageId: 0, message: "Hi how are you?", messageType: .text, time: 100, participant: isMEParticipant)
    static var previews: some View {
        let threadVM = ThreadViewModel()
        List {
            TextMessageType(message: Message(message: "Hi Hamed, I'm graet.", ownerId: 10, replyInfo: replyInfo))
            TextMessageType(message: Message(message: "Hi Hamed, I'm graet.", replyInfo: isMeReplyInfo))
        }
        .environmentObject(MessageRowCalculationViewModel())
        .environmentObject(threadVM)
        .onAppear {
            threadVM.setup(thread: MockData.thread)
        }
        .listStyle(.plain)
    }
}
