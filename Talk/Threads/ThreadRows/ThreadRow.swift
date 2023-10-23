//
//  ThreadRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadRow: View {
    @EnvironmentObject var viewModel: ThreadsViewModel
    var thread: Conversation

    var body: some View {
        HStack(spacing: 16) {
            ThreadImageView(thread: thread, threadsVM: viewModel)
                .id("\(thread.id ?? 0)\(thread.computedImageURL ?? "")")
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(thread.computedTitle)
                        .lineLimit(1)
                        .font(.iransansSubheadline)
                        .fontWeight(.light)
                    Spacer()
                    if let timeString = thread.time?.date.timeAgoSinceDateCondense {
                        Text(timeString)
                            .lineLimit(1)
                            .font(.iransansCaption2)
                            .foregroundColor(.secondary)
                    }
                    if thread.mute == true {
                        Image(systemName: "speaker.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(Color.gray)
                    }
                    if thread.type == .channel {
                        Image(systemName: "megaphone.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(Color.gray)
                    }

                    if thread.group == true, thread.type != .channel {
                        Image(systemName: "person.2.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color.gray)
                    }
                    if thread.mentioned == true {
                        Image(systemName: "at.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.main)
                    }

                    if thread.pin == true {
                        Image(systemName: "pin.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color.gray)
                    }
                }
                HStack {
                    SecondaryMessageView(thread: thread)
                    Spacer()
                    if let unreadCountString = thread.unreadCountString {
                        Text(unreadCountString)
                            .font(.iransansCaption2)
                            .padding(8)
                            .frame(height: 24)
                            .frame(minWidth: 24)
                            .foregroundColor(Color.white)
                            .background(Color.main)
                            .cornerRadius(thread.isCircleUnreadCount ? 16 : 8, antialiased: true)
                    }
                }
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
        .animation(.easeInOut, value: thread.title)
        .animation(.easeInOut, value: viewModel.activeCallThreads.count)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.selectedThraed = thread
                viewModel.sheetType = .firstConfrimation
            } label: {
                Label("General.delete", systemImage: "trash")
            }
        }
        .contextMenu {
            ThreadRowActionMenu(thread: thread)
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
