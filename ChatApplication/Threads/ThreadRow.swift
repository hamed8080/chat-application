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
            ImageLaoderView(url: thread.computedImageURL, userName: thread.title)
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(32)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(thread.title ?? "")
                        .lineLimit(1)
                        .font(.headline)
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
                }

                HStack {
                    if let message = thread.lastMessageVO?.message?.prefix(100) {
                        Text(message)
                            .lineLimit(1)
                            .font(.subheadline)
                            .clipped()
                    }
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
                ThreadIsTypingView(threadId: thread.id ?? -1)
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
