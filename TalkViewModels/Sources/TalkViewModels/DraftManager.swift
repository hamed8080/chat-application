//
//  DraftManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation

public class DraftManager {
    private let contactKey = "contact-draft-"
    private let conversationKey = "conversation-draft-"
    private init() {}

    public func get(threadId: Int) -> String? {
        UserDefaults.standard.string(forKey: getConversationKey(threadId: threadId))
    }

    public func get(contactId: Int) -> String? {
        UserDefaults.standard.string(forKey: getContactKey(contactId: contactId))
    }

    public func set(draftValue: String, threadId: Int) {
        if draftValue.isEmpty {
            clear(threadId: threadId)
        } else {
            UserDefaults.standard.setValue(draftValue, forKey: getConversationKey(threadId: threadId))
        }
        NotificationCenter.draft.post(name: .draft, object: threadId)
    }

    public func set(draftValue: String, contactId: Int) {
        if draftValue.isEmpty {
            clear(contactId: contactId)
        } else {
            UserDefaults.standard.setValue(draftValue, forKey: getContactKey(contactId: contactId))
        }
        NotificationCenter.draft.post(name: .draft, object: contactId)
    }

    public func clear(threadId: Int) {
        UserDefaults.standard.removeObject(forKey: getConversationKey(threadId: threadId))
    }

    public func clear(contactId: Int) {
        UserDefaults.standard.removeObject(forKey: getContactKey(contactId: contactId))
    }

    private func getConversationKey(threadId: Int) -> String {
        "\(conversationKey)\(threadId)"
    }

    private func getContactKey(contactId: Int) -> String {
        "\(contactKey)\(contactId)"
    }
}

public extension DraftManager {
    static let shared = DraftManager()
}
