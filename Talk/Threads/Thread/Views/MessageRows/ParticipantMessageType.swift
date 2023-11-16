//
//  ParticipantMessageType.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ParticipantMessageType: View {
    var message: Message
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            let date = Date(milliseconds: Int64(message.time ?? 0)).localFormattedTime ?? ""
            let markdownText = try! AttributedString(markdown: "\(message.addOrRemoveParticipantString) - \(date)")
            Text(markdownText)
                .foregroundStyle(Color.App.text)
                .font(.iransansSubheadline)
                .padding(2)
        }
        .padding(.horizontal, 16)
        .background(Color.App.black.opacity(0.2))
        .cornerRadius(25)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
