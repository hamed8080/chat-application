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
    let userDfault = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)

    var body: some View {
        HStack {
            if draft.isEmpty {
                ThreadLastMessageView(isSelected: isSelected, thread: thread)
            } else {
                DraftView(draft: draft)
            }
            if let lastMessageSentStatus = thread.messageStatusIcon(currentUserId: AppState.shared.user?.id) {
                Image(uiImage: lastMessageSentStatus.icon)
                    .resizable()
                    .frame(width: 14, height: 14)
                    .foregroundColor(isSelected ? Color.App.white : lastMessageSentStatus.fgColor)
                    .font(.subheadline)
            }
        }
        .onReceive(userDfault) { _ in
            let threadId = thread.id ?? 0
            draft = UserDefaults.standard.string(forKey: "draft-\(threadId)") ?? ""
        }
        .onAppear {
            let threadId = thread.id ?? 0
            if let draft = UserDefaults.standard.string(forKey: "draft-\(threadId)"), !draft.isEmpty {
                self.draft = draft
            }
        }
    }
}
