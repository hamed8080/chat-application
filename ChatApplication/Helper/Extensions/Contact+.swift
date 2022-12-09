//
//  Contact+.swift
//  ChatApplication
//
//  Created by hamed on 11/26/22.
//

import FanapPodChatSDK
import Foundation

extension Contact {
    func update(_ newContact: Contact) {
        blocked = newContact.blocked
        cellphoneNumber = newContact.cellphoneNumber
        email = newContact.email
        firstName = newContact.firstName
        hasUser = newContact.hasUser
        id = newContact.id
        image = newContact.image
        lastName = newContact.lastName
        linkedUser = newContact.linkedUser
        notSeenDuration = newContact.notSeenDuration
        timeStamp = newContact.timeStamp
        userId = newContact.userId
    }
}
