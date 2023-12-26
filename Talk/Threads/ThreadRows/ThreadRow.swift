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
    /// It is essential in the case of forwarding. We don't want to highlight the row in forwarding mode.
    var forceSelected: Bool?
    @EnvironmentObject var navVM: NavigationModel
    var isSelected: Bool { forceSelected ?? (navVM.selectedThreadId == thread.id) }
    @EnvironmentObject var viewModel: ThreadsViewModel
    var thread: Conversation

    var body: some View {
        HStack(spacing: 16) {
            ThreadImageView(thread: thread, threadsVM: viewModel)
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
                    if thread.pin == true {
                        Image(systemName: "pin.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(isSelected ? Color.App.white : Color.App.gray6)
                    }

                    ThreadTimeText(thread: thread, isSelected: isSelected)
                }
                HStack {
                    SecondaryMessageView(isSelected: isSelected, thread: thread)
                        .environmentObject(ThreadEventViewModel(threadId: thread.id ?? -1))
                    Spacer()
                    ThreadUnreadCount(isSelected: isSelected)
                        .environmentObject(thread)
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

struct ThreadUnreadCount: View {
    @EnvironmentObject var thread: Conversation
    let isSelected: Bool
    @State private var unreadCountString = ""
    @EnvironmentObject var viewModel: ThreadsViewModel

    var body: some View {
        ZStack {
            if !unreadCountString.isEmpty {
                Text(unreadCountString)
                    .font(.iransansBoldCaption2)
                    .padding(thread.isCircleUnreadCount ? 4 : 6)
                    .frame(height: 24)
                    .frame(minWidth: 24)
                    .foregroundStyle(thread.mute == true ? Color.App.text : Color.App.textOverlay)
                    .background(thread.mute == true ? Color.App.gray7 : isSelected ? Color.App.white : Color.App.primary)
                    .clipShape(RoundedRectangle(cornerRadius:(thread.isCircleUnreadCount ? 16 : 10)))

            }
        }
        .animation(.easeInOut, value: unreadCountString)
        .onReceive(thread.objectWillChange) { newValue in
            Task {
                await updateCountAsync()
            }
        }
        .task {
            await updateCountAsync()
        }
    }

    private func updateCountAsync() async {
        unreadCountString = thread.unreadCountString ?? ""
    }
}

struct ThreadTimeText: View {
    let thread: Conversation
    let isSelected: Bool
    @State private var timeString: String = ""

    var body: some View {
        ZStack {
            if !timeString.isEmpty {
                Text(timeString)
                    .lineLimit(1)
                    .font(.iransansCaption2)
                    .foregroundColor(isSelected ? Color.App.white : Color.App.hint)
            }
        }
        .animation(.easeInOut, value: timeString)
        .onReceive(thread.objectWillChange) { newValue in
            Task {
                await updateTimeAsync()
            }
        }
        .task {
            await updateTimeAsync()
        }
    }

    private func updateTimeAsync() async {
        timeString = thread.time?.date.localTimeOrDate ?? ""
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
