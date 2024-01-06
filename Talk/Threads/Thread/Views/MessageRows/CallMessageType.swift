//
//  CallMessageType.swift
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

struct CallMessageType: View {
    var message: Message
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center) {
            if let time = message.time {
                let date = Date(milliseconds: Int64(time))
                HStack(spacing: 2) {
                    Text(message.type == .endCall ? "Thread.callEnded" : "Thread.callStarted")
                    Text("\(date.localFormattedTime ?? "")")
                }
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBody)
                .padding(2)
            }

            Image(systemName: message.type == .startCall ? "phone.arrow.up.right.fill" : "phone.down.fill")
                .resizable()
                .scaledToFit()
                .frame(width: message.type == .startCall ? 12 : 18, height: message.type == .startCall ? 12 : 18)
                .foregroundStyle(message.type == .startCall ? Color.App.color2 : Color.App.red)
        }
        .padding(.horizontal, 16)
        .background(Color.App.textPrimary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius:(25)))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
