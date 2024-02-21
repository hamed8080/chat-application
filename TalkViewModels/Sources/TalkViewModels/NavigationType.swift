//
//  NavigationType.swift
//
//
//  Created by hamed on 11/15/23.
//

import Foundation
import ChatModels

public enum NavigationType: Hashable {
    case threadViewModel(ThreadViewModel)
    case contact(Contact)
    case threadDetil(ThreadDetailViewModel)
    case preference(PreferenceNavigationValue)
    case assistant(AssistantNavigationValue)
    case log(LogNavigationValue)
    case archives(ArchivesNavigationValue)
    case language(LanguageNavigationValue)
    case blockedContacts(BlockedContactsNavigationValue)
    case notificationSettings(NotificationSettingsNavigationValue)
    case automaticDownloadsSettings(AutomaticDownloadsNavigationValue)
    case support(SupportNavigationValue)
    case messageParticipantsSeen(MessageParticipantsSeenNavigationValue)
    case editProfile(EditProfileNavigationValue)
    case loadTests(LoadTestsNavigationValue)
}
