//
//  ConversationCallMessageType.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI

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
                .font(.iransansFootnote)
                .foregroundColor(color == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                .padding(2)
            }

            Image(systemName: message.type == .startCall ? "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(message.type == .startCall ? Color.App.green : Color.App.red)
        }
        .padding([.leading], 2)
        .padding([.trailing], 8)
        .background(Color.App.bgSecond)
        .cornerRadius(6)
    }
}
