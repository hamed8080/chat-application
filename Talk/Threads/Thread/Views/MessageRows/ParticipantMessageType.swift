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
    @State var markdownText: AttributedString = .init()
    var message: Message
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(markdownText)
                .foregroundStyle(Color.App.white)
                .multilineTextAlignment(.center)
                .font(.iransansBody)
                .padding(2)
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius:(25)))
        .frame(maxWidth: .infinity)
        .onAppear {
            Task.detached {
                let date = Date(milliseconds: Int64(message.time ?? 0)).localFormattedTime ?? ""
                let markdownText = try! AttributedString(markdown: "\(message.addOrRemoveParticipantString ?? "") - \(date)")
                await MainActor.run {
                    self.markdownText = markdownText
                }
            }
        }
    }
}
