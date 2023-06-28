//
//  SecondaryMessageView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import ChatAppUI
import ChatAppViewModels
import ChatModels
import Combine
import SwiftUI

struct SecondaryMessageView: View {
    var thread: Conversation
    @State private var draft: String = ""
    @State private var cancelable: AnyCancellable?

    var body: some View {
        HStack {
            if draft.isEmpty {
                ThreadLastMessageView(thread: thread)
            } else {
                DraftView(draft: draft)
            }
        }
        .onAppear {
            let threadId = thread.id ?? 0
            if let draft = UserDefaults.standard.string(forKey: "draft-\(threadId)"), !draft.isEmpty {
                self.draft = draft
            }
            cancelable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
                .map { _ in
                    UserDefaults.standard.string(forKey: "draft-\(threadId)") ?? ""
                }
                .sink { newValue in
                    draft = newValue
                }
        }
    }
}
