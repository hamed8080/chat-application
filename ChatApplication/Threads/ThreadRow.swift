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
        HStack {
            ImageLaoderView(url: thread.computedImageURL, userName: thread.title)
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(32)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(thread.title ?? "")
                        .font(.headline)
                    if thread.mute == true {
                        Image(systemName: "speaker.slash.fill")
                            .resizable()
                            .frame(width: 12, height: 12)
                            .scaledToFit()
                            .foregroundColor(Color.gray)
                    }
                }

                if let message = thread.lastMessageVO?.message?.prefix(100) {
                    Text(message)
                        .lineLimit(1)
                        .font(.subheadline)
                        .clipped()
                }
                ThreadIsTypingView(threadId: thread.id ?? -1)
            }
            Spacer()
            JoinToGroupCallView(thread: thread)
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

struct ThreadRow_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        ThreadRow(thread: MockData.thread)
            .environmentObject(vm)
            .onAppear {
                vm.setup(thread: MockData.thread)
                vm.thread?.pin = true
                vm.thread?.unreadCount = 10
                vm.objectWillChange.send()
            }
    }
}
