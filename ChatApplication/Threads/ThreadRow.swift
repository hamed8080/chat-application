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
    @ObservedObject var viewModel: ThreadViewModel

    var body: some View {
        Button(action: {}, label: {
            HStack {
                viewModel.imageLoader.imageView
                    .font(.system(size: 16).weight(.heavy))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(32)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.thread.title ?? "")
                            .font(.headline)
                        if viewModel.thread.mute == true {
                            Image(systemName: "speaker.slash.fill")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .scaledToFit()
                                .foregroundColor(Color.gray)
                        }
                    }

                    if let message = viewModel.thread.lastMessageVO?.message?.prefix(100) {
                        Text(message)
                            .lineLimit(1)
                            .font(.subheadline)
                            .clipped()
                    }
                    ThreadIsTypingView(threadId: viewModel.threadId)
                }
                Spacer()
                if let unreadCountString = viewModel.thread.unreadCountString {
                    Text(unreadCountString)
                        .font(.system(size: 13))
                        .padding(8)
                        .frame(height: 24)
                        .frame(minWidth: 24)
                        .foregroundColor(Color.white)
                        .background(Color.orange)
                        .cornerRadius(viewModel.thread.isCircleUnreadCount ? 16 : 8, antialiased: true)
                }

                if viewModel.thread.mentioned == true {
                    Image(systemName: "at.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.orange)
                }

                if viewModel.thread.pin == true {
                    Image(systemName: "pin.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color.orange)
                }
            }
            .contentShape(Rectangle())
            .padding([.leading, .trailing], 8)
            .padding([.top, .bottom], 4)
        })
        .animation(.easeInOut, value: viewModel.thread.lastMessageVO?.message)
        .animation(.easeInOut, value: viewModel.thread)
        .animation(.easeInOut, value: viewModel.thread.pin)
        .animation(.easeInOut, value: viewModel.thread.mute)
        .animation(.easeInOut, value: viewModel.thread.unreadCount)
        .animation(.easeInOut, value: viewModel.thread.title)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.delete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                viewModel.togglePin()
            } label: {
                Label((viewModel.thread.pin ?? false) ? "UnPin" : "Pin", systemImage: "pin")
            }

            Button {
                viewModel.clearHistory()
            } label: {
                Label("Clear History", systemImage: "clock")
            }

            Button {
                viewModel.toggleMute()
            } label: {
                Label((viewModel.thread.mute ?? false) ? "Unmute" : "Mute", systemImage: "speaker.slash")
            }

            Button {
                viewModel.threadsViewModel?.showAddThreadToTag(viewModel.thread)
            } label: {
                Label("Add To Folder", systemImage: "folder.badge.plus")
            }

            Button {
                viewModel.spamPV()
            } label: {
                Label("Spam", systemImage: "ladybug")
            }

            Button(role: .destructive) {
                viewModel.leave()
            } label: {
                Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
            }

            if viewModel.thread.admin == true {
                Button(role: .destructive) {
                    viewModel.delete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            Button {
                viewModel.toggleArchive()
            } label: {
                Label(viewModel.thread.isArchive == false ? "Archive" : "Unarchive", systemImage: viewModel.thread.isArchive == false ? "tray.and.arrow.down" : "tray.and.arrow.up")
            }

            if viewModel.canAddParticipant {
                Button {
                    viewModel.threadsViewModel?.showAddParticipants(viewModel.thread)
                } label: {
                    Label("Invite", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
    }
}

struct ThreadRow_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel(thread: MockData.thread)
        ThreadRow(viewModel: vm)
            .onAppear {
                vm.thread.pin = true
                vm.thread.unreadCount = 10
                vm.objectWillChange.send()
            }
    }
}
