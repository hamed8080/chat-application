//
//  ThreadRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI
import Combine

struct ThreadRow: View {
    @ObservedObject
    var viewModel: ThreadViewModel

    var body: some View {
        let _ = Self._printChanges()
        Button(action: {}, label: {
            HStack {
                let token = EnvironmentValues().isPreview ? "FAKE_TOKEN" : TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken
                Avatar(
                    url: viewModel.thread.image,
                    userName: viewModel.thread.inviter?.username?.uppercased(),
                    token: token
                )
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
                    }

                    if viewModel.isTyping {
                        Text("is typing...")
                            .frame(width: 72, alignment: .leading)
                            .lineLimit(1)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.orange)
                    }
                }
                Spacer()
                if let call = viewModel.threadsViewModel?.callsToJoin.first(where: {$0.conversation?.id == viewModel.threadId}) {
                    Button {
                        viewModel.threadsViewModel?.joinToCall(call)
                    } label: {
                        Image(systemName: call.type == .videoCall ? "video.fill" : "phone.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .padding()
                            .foregroundColor(Color.green)
                    }
                }
                if viewModel.thread.pin == true {
                    Image(systemName: "pin.fill")
                        .foregroundColor(Color.orange)
                }
                if let unreadCount = viewModel.thread.unreadCount, unreadCount > 0, let unreadCountString = String(unreadCount) {
                    let isCircle = unreadCount < 10 // two number and More require oval shape
                    let computedString = unreadCount < 1000 ? unreadCountString : "\(unreadCount / 1000)K+"
                    Text(computedString)
                        .font(.system(size: 13))
                        .padding(8)
                        .frame(height: 24)
                        .frame(minWidth: 24)
                        .foregroundColor(Color.white)
                        .background(Color.orange)
                        .cornerRadius(isCircle ? 16 : 8, antialiased: true)
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
        .animation(.easeInOut, value: viewModel.isTyping)
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
                viewModel.showManageFolder.toggle()
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
                Label( viewModel.thread.isArchive == false ? "Archive" : "Unarchive", systemImage: viewModel.thread.isArchive == false ? "tray.and.arrow.down" : "tray.and.arrow.up")
            }

            if viewModel.canAddParticipant {
                Button {
                    viewModel.showAddPaticipantToThread.toggle()
                } label: {
                    Label("Invite", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
    }
}

struct ThreadRow_Previews: PreviewProvider {

    static var previews: some View {
        ThreadRow(viewModel: ThreadViewModel(thread: MockData.thread))
    }
}
