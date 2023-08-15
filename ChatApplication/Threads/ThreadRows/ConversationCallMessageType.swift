//
//  ConversationCallMessageType.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatAppUI
import ChatModels
import SwiftUI

struct ConversationCallMessageType: View {
    var message: Message
    @Environment(\.colorScheme) var color

    var body: some View {
        HStack(alignment: .center) {
            if let time = message.time {
                let date = Date(milliseconds: Int64(time))
                HStack(spacing: 2) {
                    Text(message.type == .endCall ? "Thread.callEnded" : "Thread.callStarted")
                    Text("\(date.timeAgoSinceDateCondense ?? "")")
                        .fontWeight(.bold)
                }
                .font(.footnote)
                .foregroundColor(color == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                .padding(2)
            }

            Image(systemName: message.type == .startCall ? "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(message.type == .startCall ? Color.green : Color.red)
        }
        .padding([.leading], 2)
        .padding([.trailing], 8)
        .background(Color.tableItem.opacity(color == .dark ? 1 : 0.3))
        .cornerRadius(6)
    }
}
