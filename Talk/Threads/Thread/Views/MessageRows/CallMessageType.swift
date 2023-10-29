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
                    Text("\(date.timeAgoSinceDateCondense ?? "")")
                        .fontWeight(.bold)
                }
                .foregroundColor(Color.App.primary.opacity(0.8))
                .font(.iransansSubheadline)
                .padding(2)
            }

            Image(systemName: message.type == .startCall ? "arrow.down.left" : "arrow.up.right")
                .resizable()
                .frame(width: 10, height: 10)
                .scaledToFit()
                .foregroundColor(message.type == .startCall ? Color.App.green : Color.App.red)
        }
        .padding([.leading, .trailing])
        .background(colorScheme == .light ? Color(CGColor(red: 0.718, green: 0.718, blue: 0.718, alpha: 0.8)) : Color.App.gray1.opacity(0.1))
        .cornerRadius(6)
    }
}
