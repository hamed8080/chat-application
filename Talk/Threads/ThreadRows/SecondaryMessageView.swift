//
//  SecondaryMessageView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import ChatModels
import Combine
import SwiftUI
import TalkUI
import TalkViewModels

struct SecondaryMessageView: View {
    let isSelected: Bool
    var thread: Conversation
    @State private var draft: String = ""
    @State private var cancelable: AnyCancellable?

    var body: some View {
        HStack {
            if draft.isEmpty {
                ThreadLastMessageView(isSelected: isSelected, thread: thread)
                    .id(thread.lastMessageVO?.id)
            } else {
                DraftView(draft: draft)
                    .id(draft)
            }
        }
        .animation(.easeInOut, value: draft.isEmpty)
        .onReceive(NotificationCenter.draft.publisher(for: .draft)) { notif in
            onDraftChanged(id: notif.object as? Int)
        }
        .onAppear {
            let threadId = thread.id ?? 0
            if let draft = DraftManager.shared.get(threadId: threadId), !draft.isEmpty {
                self.draft = draft
            }
        }
    }

    private func onDraftChanged(id: Int?) {
        let threadId = thread.id ?? 0
        if id == threadId {
            draft = DraftManager.shared.get(threadId: threadId) ?? ""
        }
    }
}


struct MutableMessageStatusView: View {
    let isSelected: Bool
    @EnvironmentObject var thread: Conversation

    var body: some View {
        if let lastMessageSentStatus = thread.messageStatusIcon(currentUserId: AppState.shared.user?.id) {
            Image(uiImage: lastMessageSentStatus.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundColor(isSelected ? Color.App.white : lastMessageSentStatus.fgColor)
                .font(.subheadline)
                .offset(y: -2)
        }
    }
}
