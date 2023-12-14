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
    @EnvironmentObject var navVM: NavigationModel
    var isSelected: Bool { navVM.selectedThreadId == thread.id }
    @EnvironmentObject var viewModel: ThreadsViewModel
    var thread: Conversation

    var body: some View {
        HStack(spacing: 16) {
            ThreadImageView(thread: thread, threadsVM: viewModel)
                .id("\(thread.id ?? 0)\(thread.computedImageURL ?? "")")
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if thread.type == .channel {
                        Image(systemName: "megaphone.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(isSelected ? Color.App.white : Color.App.gray6)
                    }

                    if thread.group == true, thread.type != .channel {
                        Image(systemName: "person.2.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(isSelected ? Color.App.white : Color.App.gray6)
                    }
                    Text(thread.computedTitle)
                        .lineLimit(1)
                        .font(.iransansSubheadline)
                        .fontWeight(.light)
                    if thread.mute == true {
                        Image(systemName: "speaker.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(isSelected ? Color.App.white : Color.App.gray6)
                    }
                    Spacer()
                    if let timeString = thread.time?.date.localFormattedTime {
                        Text(timeString)
                            .lineLimit(1)
                            .font(.iransansCaption2)
                            .foregroundColor(isSelected ? Color.App.white : Color.App.hint)
                    }

                    if thread.pin == true {
                        Image(systemName: "pin.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(isSelected ? Color.App.white : Color.App.gray6)
                    }
                }
                HStack {
                    SecondaryMessageView(isSelected: isSelected, thread: thread)
                        .environmentObject(ThreadEventViewModel(threadId: thread.id ?? -1))
                    Spacer()
                    if let unreadCountString = thread.unreadCountString {
                        Text(unreadCountString)
                            .font(.iransansCaption2)
                            .padding(thread.isCircleUnreadCount ? 4 : 6)
                            .frame(height: 24)
                            .frame(minWidth: 24)
                            .foregroundStyle(Color.App.textOverlay)
                            .background(isSelected ? Color.App.white : Color.App.primary)
                            .clipShape(RoundedRectangle(cornerRadius:(thread.isCircleUnreadCount ? 16 : 10)))
                    }

                    ThreadMentionSign()
                        .environmentObject(thread)
                }
            }
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .animation(.easeInOut, value: thread.lastMessageVO?.message)
        .animation(.easeInOut, value: thread)
        .animation(.easeInOut, value: thread.pin)
        .animation(.easeInOut, value: thread.mute)
        .animation(.easeInOut, value: thread.title)
        .animation(.easeInOut, value: viewModel.activeCallThreads.count)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteThreadView(threadId: thread.id))                
            } label: {
                Label("General.delete", systemImage: "trash")
            }
        }
        .contextMenu {
            ThreadRowActionMenu(thread: thread)
        }
    }
}

struct ThreadMentionSign: View {
    @EnvironmentObject var thread: Conversation

    var body: some View {
        if thread.mentioned == true {
            Text("@")
                .font(.iransansCaption)
                .padding(6)
                .frame(height: 24)
                .frame(minWidth: 24)
                .foregroundStyle(Color.App.textOverlay)
                .background(Color.App.primary)
                .clipShape(RoundedRectangle(cornerRadius:(12)))
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
