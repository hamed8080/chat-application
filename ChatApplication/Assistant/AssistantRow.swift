//  AssistantRow.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import Chat
import ChatModels
import SwiftUI

struct AssistantRow: View {
    var assistant: Assistant

    var body: some View {
        ZStack(alignment: .leading) {
            Text(assistant.participant?.name ?? "")
                .font(.iransansCaption)
                .padding()
        }
        .textSelection(.enabled)
    }
}

struct AssistantRow_Previews: PreviewProvider {
    static var assistant: Assistant {
        let participant = Participant(name: "Hamed Hosseini")
        let roles: [Roles] = [.addNewUser, .editThread, .editMessageOfOthers]
        return Assistant(id: 1, participant: participant, roles: roles)
    }

    static var previews: some View {
        AssistantRow(assistant: assistant)
    }
}
