//
//  ObjectsContainer.swift
//  ChatApplication
//
//  Created by hamed on 1/31/23.
//

import Combine
import Foundation

class ObjectsContainer: ObservableObject {
    @Published var navVM = NavigationModel()
    @Published var loginVM = LoginViewModel()
    @Published var contactsVM = ContactsViewModel()
    @Published var threadsVM = ThreadsViewModel()
    @Published var tagsVM = TagsViewModel()
    @Published var settingsVM = SettingViewModel()
    @Published var tokenVM = TokenManager.shared
    init() {}

    func reset() {
        threadsVM.clear()
        contactsVM.clear()
        tagsVM.clear()
        tagsVM.getTagList()
        navVM.clear()
        navVM.setup()
        threadsVM.getThreads()
        contactsVM.getContacts()
    }
}
