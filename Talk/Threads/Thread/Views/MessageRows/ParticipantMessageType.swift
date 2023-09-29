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
            let date = Date(milliseconds: Int64(message.time ?? 0)).timeAgoSinceDateCondense ?? ""
            let markdownText = try! AttributedString(markdown: "\(message.addOrRemoveParticipantString) - \(date)")
            Text(markdownText)
                .foregroundColor(Color.primary.opacity(0.8))
                .font(.iransansBoldCaption2)
                .padding(2)

            if let iconName = message.iconName {
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: 12, height: 12)
                    .foregroundColor(message.type == .participantJoin ? Color.green : Color.red)
                    .padding([.leading, .trailing], 6)
                    .scaledToFit()
            }
        }
        .padding([.leading, .trailing])
        .background(colorScheme == .light ? Color(CGColor(red: 0.718, green: 0.718, blue: 0.718, alpha: 0.8)) : Color.gray.opacity(0.1))
        .cornerRadius(6)
        .frame(maxWidth: .infinity)
    }
}
