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
import TalkModels
import ActionableContextMenu

struct ThreadRow: View {
    /// It is essential in the case of forwarding. We don't want to highlight the row in forwarding mode.
    var forceSelected: Bool?
    @State private var isSelected: Bool = false
    @EnvironmentObject var viewModel: ThreadsViewModel
    var thread: Conversation
    let onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            SelectedThreadBar(thread: thread, isSelected: isSelected)
            ThreadImageView(thread: thread, threadsVM: viewModel)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if thread.type?.isChannelType == true {
                        Image(systemName: "megaphone.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
                    }

                    if thread.group == true, thread.type?.isChannelType == false {
                        Image(systemName: "person.2.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
                    }
                    Text(thread.titleRTLString)
                        .lineLimit(1)
                        .font(.iransansSubheadline)
                        .fontWeight(.semibold)
                    if thread.mute == true {
                        Image(systemName: "speaker.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
                    }
                    Spacer()
                    if thread.pin == true {
                        Image(systemName: "pin.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
                    }

                    ThreadTimeText(thread: thread, isSelected: isSelected)
                }
                HStack {
                    SecondaryMessageView(isSelected: isSelected, thread: thread)
                        .environmentObject(viewModel.threadEventModels.first{$0.threadId == thread.id} ?? .init(threadId: thread.id ?? 0))
                    Spacer()
                    ThreadUnreadCount(isSelected: isSelected)
                        .environmentObject(thread)
                    ThreadMentionSign()
                        .environmentObject(thread)
                }
            }
            .contentShape(Rectangle())
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
        .animation(.easeInOut, value: thread.lastMessageVO?.message)
        .animation(.easeInOut, value: thread)
        .animation(.easeInOut, value: thread.pin)
        .animation(.easeInOut, value: thread.mute)
        .animation(.easeInOut, value: thread.title)
        .animation(.easeInOut, value: viewModel.activeCallThreads.count)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteThreadDialog(threadId: thread.id))
            } label: {
                Label("General.delete", systemImage: "trash")
            }
        }
        .customContextMenu(
            id: thread.id,
            self: ThreadRowSelfContextMenu(thread: thread, viewModel: viewModel),
            addedX: 8
        ) {
            onTap?()
        } menus: {
            ThreadRowContextMenu(thread: thread, viewModel: viewModel)
        }
        .onReceive(AppState.shared.objectsContainer.navVM.objectWillChange) { _ in
            setSelection()
        }.onAppear {
            setSelection()
        }
    }

    private func setSelection() {
        if AppState.shared.objectsContainer.navVM.selectedId == thread.id {
            isSelected = forceSelected ?? (AppState.shared.objectsContainer.navVM.selectedId == thread.id)
        } else if isSelected == true {
            isSelected = false
        }
    }
}

struct ThreadRowSelfContextMenu: View {
    let thread: Conversation
    let viewModel: ThreadsViewModel
    @Environment(\.layoutDirection) var direction
    @EnvironmentObject var ctxVM: ContextMenuModel

    var body: some View {
        ThreadRow(thread: thread, onTap: nil)
            .frame(height: 72)
            .frame(maxWidth: min(400, ctxVM.containerSize.width - 18)) /// 400 for ipad side bar
            .background(Color.App.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .environmentObject(AppState.shared.objectsContainer.navVM)
            .environmentObject(viewModel)
            .environment(\.layoutDirection, direction == .leftToRight && Language.isRTL ? .rightToLeft : .leftToRight)
    }
}

struct ThreadRowContextMenu: View {
    let thread: Conversation
    let viewModel: ThreadsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThreadRowActionMenu(showPopover: .constant(true), thread: thread)
                .environmentObject(viewModel)
        }
        .foregroundColor(.primary)
        .frame(width: 246)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius:((12))))
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
                .foregroundStyle(Color.App.textPrimary)
                .background(Color.App.accent)
                .clipShape(RoundedRectangle(cornerRadius:(12)))
        }
    }
}

struct SelectedThreadBar: View {
    let thread: Conversation
    let isSelected: Bool

    var body: some View {
        Rectangle()
            .fill(Color.App.accent)
            .frame(width: isSelected ? 4 : 0)
            .frame(minHeight: 0, maxHeight: .infinity)
            .animation(.easeInOut, value: isSelected)
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
                    .foregroundStyle(thread.mute == true ? Color.App.white : isSelected ? Color.App.textSecondary : Color.App.textPrimary)
                    .background(thread.mute == true ? Color.App.iconSecondary : isSelected ? Color.App.white : Color.App.accent)
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
                    .foregroundColor(isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
            }
        }
        .animation(.easeInOut, value: timeString)
        .animation(.easeInOut, value: isSelected)
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
        ThreadRow(thread: thread) {

        }.environmentObject(ThreadsViewModel())
    }
}
