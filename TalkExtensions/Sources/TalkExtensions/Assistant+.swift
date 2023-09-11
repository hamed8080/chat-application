//
//  Assistant+.swift
//  TalkExtensions
//
//  Created by hamed on 11/26/22.
//

import ChatModels
import Foundation

public extension Assistant {
    func update(_ newAssistant: Assistant) {
        id = newAssistant.id
        contactType = newAssistant.contactType
        assistant = newAssistant.assistant
        participant = newAssistant.participant
        roles = newAssistant.roles
        block = newAssistant.block
    }
}
