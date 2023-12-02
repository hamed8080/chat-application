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
            let markdownText = try! AttributedString(markdown: "\(message.addOrRemoveParticipantString ?? "") - \(date)")
            Text(markdownText)
                .foregroundStyle(Color.App.text)
                .multilineTextAlignment(.center)
                .font(.iransansBody)
                .padding(2)
        }
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .padding(.horizontal, 16)
        .background(Color.App.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius:(25)))
        .frame(maxWidth: .infinity)
    }
}
