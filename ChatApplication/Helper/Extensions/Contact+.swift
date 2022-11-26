//
//  Contact+.swift
//  ChatApplication
//
//  Created by hamed on 11/26/22.
//

import Foundation
import FanapPodChatSDK

extension Contact {
    func update(_ newContact: Contact) {
        self.blocked = newContact.blocked
        self.cellphoneNumber = newContact.cellphoneNumber
        self.email = newContact.email
        self.firstName = newContact.firstName
        self.hasUser = newContact.hasUser
        self.id = newContact.id
        self.image = newContact.image
        self.lastName = newContact.lastName
        self.linkedUser = newContact.linkedUser
        self.notSeenDuration = newContact.notSeenDuration
        self.timeStamp = newContact.timeStamp
        self.userId = newContact.userId
    }
}
