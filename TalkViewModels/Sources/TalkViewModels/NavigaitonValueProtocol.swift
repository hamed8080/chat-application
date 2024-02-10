//
//  PreferenceNavigationValue.swift
//
//
//  Created by hamed on 11/15/23.
//

import Foundation
import ChatModels

public protocol NavigationTitle {
    var title: String { get }
}

public protocol NavigaitonValueProtocol: Hashable, NavigationTitle {
}

public struct PreferenceNavigationValue: NavigaitonValueProtocol {
    public let title: String = "Settings.title"
    public init() {}
}

public struct AssistantNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Assistant.Assistants"
    public init() {}
}

public struct LogNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Logs.title"
    public init() {}
}

public struct ArchivesNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Tab.archives"
    public init() {}
}

public struct LanguageNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.language"
    public init() {}
}

public struct BlockedContactsNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Contacts.blockedList"
    public init() {}
}

public struct NotificationSettingsNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.notifictionSettings"
    public init() {}
}

public struct AutomaticDownloadsNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.download"
    public init() {}
}

public struct SupportNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.support"
    public init() {}
}

public struct MessageParticipantsSeenNavigationValue: NavigaitonValueProtocol {
    public var title: String = "SeenParticipants.title"
    public let message: Message
    public let threadVM: ThreadViewModel

    public init(message: Message, threadVM: ThreadViewModel) {
        self.message = message
        self.threadVM = threadVM
    }
}

public struct ConversationNavigationValue: NavigaitonValueProtocol {
    public var viewModel: ThreadViewModel
    public var title: String { viewModel.thread.computedTitle }

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }
}

public struct EditProfileNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.EditProfile.title"
    public init() {}
}
