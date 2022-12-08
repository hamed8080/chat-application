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
                            .clipped()
                    }
                    ThreadIsTypingView(threadId: viewModel.threadId)
                }
                Spacer()
                JoinToGroupCallView()
                    .environmentObject(viewModel)
                if viewModel.thread.pin == true {
                    Image(systemName: "pin.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color.orange)
                }
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
        .animation(.easeInOut, value: viewModel.groupCallIdToJoin)
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

struct JoinToGroupCallView: View {
    @EnvironmentObject
    var viewModel: ThreadViewModel

    @State
    var showCallToJoin: Bool = false

    @State
    private var variable = 0.0

    @State
    var timer: Timer?

    var body: some View {
        if let callIdToJoin = viewModel.groupCallIdToJoin {
            Button {
                CallViewModel.joinToCall(callIdToJoin)
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
                timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
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
        let vm = ThreadViewModel(thread: MockData.thread)
        ThreadRow(viewModel: vm)
            .onAppear {
                vm.thread.pin = true
                vm.thread.unreadCount = 10
                vm.objectWillChange.send()
            }
    }
}
