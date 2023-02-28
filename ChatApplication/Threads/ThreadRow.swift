//
//  ThreadRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

struct ThreadRow: View {
    @EnvironmentObject var viewModel: ThreadsViewModel
    var thread: Conversation
    var canAddParticipant: Bool { thread.group ?? false && thread.admin ?? false == true }

    var body: some View {
        HStack(spacing: 8) {
            ImageLaoderView(url: thread.computedImageURL, metaData: thread.metadata, userName: thread.title)
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(32)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(thread.title ?? "")
                        .lineLimit(1)
                        .font(.headline.bold())
                    if thread.mute == true {
                        Image(systemName: "speaker.slash.fill")
                            .resizable()
                            .frame(width: 12, height: 12)
                            .scaledToFit()
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                    if let timeString = thread.time?.date.timeAgoSinceDatecCondence {
                        Text(timeString)
                            .lineLimit(1)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    if let lastMessageSentStatus = thread.messageStatusIcon {
                        Image(uiImage: lastMessageSentStatus.icon)
                            .resizable()
                            .frame(width: 14, height: 14)
                            .foregroundColor(lastMessageSentStatus.fgColor)
                            .font(.subheadline)
                    }
                }
                HStack {
                    ThreadLastMessageView(thread: thread)
                    Spacer()
                    if let unreadCountString = thread.unreadCountString {
                        Text(unreadCountString)
                            .font(.system(size: 13))
                            .padding(8)
                            .frame(height: 24)
                            .frame(minWidth: 24)
                            .foregroundColor(Color.white)
                            .background(Color.orange)
                            .cornerRadius(thread.isCircleUnreadCount ? 16 : 8, antialiased: true)
                    }

                    if thread.mentioned == true {
                        Image(systemName: "at.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color.orange)
                    }

                    if thread.pin == true {
                        Image(systemName: "pin.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color.orange)
                    }
                }
                JoinToGroupCallView(thread: thread)
                ThreadEventView()
                    .environmentObject(ThreadEventViewModel(threadId: thread.id ?? -1))
            }
        }
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 4)
        .animation(.easeInOut, value: thread.lastMessageVO?.message)
        .animation(.easeInOut, value: thread)
        .animation(.easeInOut, value: thread.pin)
        .animation(.easeInOut, value: thread.mute)
        .animation(.easeInOut, value: thread.unreadCount)
        .animation(.easeInOut, value: thread.title)
        .animation(.easeInOut, value: viewModel.activeCallThreads.count)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.delete(thread)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                viewModel.togglePin(thread)
            } label: {
                Label((thread.pin ?? false) ? "UnPin" : "Pin", systemImage: "pin")
            }

            Button {
                viewModel.clearHistory(thread)
            } label: {
                Label("Clear History", systemImage: "clock")
            }

            Button {
                viewModel.toggleMute(thread)
            } label: {
                Label((thread.mute ?? false) ? "Unmute" : "Mute", systemImage: "speaker.slash")
            }

            Button {
                viewModel.showAddThreadToTag(thread)
            } label: {
                Label("Add To Folder", systemImage: "folder.badge.plus")
            }

            Button {
                viewModel.spamPV(thread)
            } label: {
                Label("Spam", systemImage: "ladybug")
            }

            Button(role: .destructive) {
                viewModel.leave(thread)
            } label: {
                Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
            }

            if thread.admin == true {
                Button(role: .destructive) {
                    viewModel.delete(thread)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            Button {
                viewModel.toggleArchive(thread)
            } label: {
                Label(thread.isArchive == false ? "Archive" : "Unarchive", systemImage: thread.isArchive == false ? "tray.and.arrow.down" : "tray.and.arrow.up")
            }

            if canAddParticipant {
                Button {
                    viewModel.showAddParticipants(thread)
                } label: {
                    Label("Invite", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
    }
}

struct JoinToGroupCallView: View {
    @EnvironmentObject var viewModel: ThreadsViewModel
    @State private var variable = 0.0
    @State var timer: Timer?
    let thread: Conversation

    var body: some View {
        if let callIdToJoin = viewModel.activeCallThreads.first(where: { $0.threadId == thread.id }) {
            Button {
                CallViewModel.joinToCall(callIdToJoin.callId)
            } label: {
                if #available(iOS 16.0, *) {
                    Image(systemName: "phone.and.waveform.fill", variableValue: variable)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .padding(8)
                        .foregroundColor(Color.green)
                } else {
                    Image(systemName: "phone.and.waveform.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .padding(8)
                        .foregroundColor(Color.green)
                }
            }
            .transition(.asymmetric(insertion: .scale, removal: .scale))
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                    withAnimation(.easeInOut) {
                        if variable >= 1 {
                            variable = 0
                        } else {
                            variable += 0.15
                        }
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}

struct ThreadLastMessageView: View {
    var thread: Conversation
    var lastMsgVO: Message? { thread.lastMessageVO }

    var body: some View {
        VStack(spacing: 2) {
            if let name = lastMsgVO?.participant?.name, thread.group == true {
                Text(name)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .foregroundColor(.orange)
            }

            HStack {
                if lastMsgVO?.isFileType == true, let iconName = lastMsgVO?.iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.blue)
                }
                if let message = thread.lastMessageVO?.message {
                    Text(message)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundColor(.secondaryLabel)
                }

                if lastMsgVO?.isFileType == true, lastMsgVO?.message.isEmptyOrNil == true, let fileStringName = lastMsgVO?.fileStringName {
                    Text(fileStringName)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundColor(.secondaryLabel)
                }
                Spacer()
            }
            if let message = lastMsgVO, message.type == .endCall || message.type == .startCall {
                ConversationCallMessageType(message: message)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .truncationMode(Text.TruncationMode.tail)
        .font(.subheadline)
        .fontDesign(.rounded)
        .clipped()
    }
}

struct ConversationCallMessageType: View {
    var message: Message
    @Environment(\.colorScheme) var color

    var body: some View {
        HStack(alignment: .center) {
            if let time = message.time, let date = Date(milliseconds: Int64(time)) {
                Text("Call \(message.type == .endCall ? "ended" : "started") - \(date.timeAgoSinceDatecCondence ?? "")")
                    .font(.footnote)
                    .foregroundColor(color == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    .padding(2)
            }

            Image(systemName: message.type == .startCall ? "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(message.type == .startCall ? Color.green : Color.red)
        }
        .padding([.leading], 2)
        .padding([.trailing], 8)
        .background(Color.tableItem.opacity(color == .dark ? 1 : 0.3))
        .cornerRadius(6)
    }
}

struct ThreadRow_Previews: PreviewProvider {
    static var thread: Conversation {
        let thread = MockData.thread
        thread.title = "Hamed  Hosseini"
        thread.time = 1_675_186_636_000
        thread.pin = true
        thread.mute = true
        thread.mentioned = true
        thread.unreadCount = 20
        return thread
    }

    static var previews: some View {
        ThreadRow(thread: thread)
            .environmentObject(ThreadsViewModel())
    }
}
