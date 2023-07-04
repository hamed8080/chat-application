//
//  ThreadPinMessage.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ThreadPinMessage: View {
    private var messages: [Message] { threadVM.thread?.pinMessages ?? [] }
    @EnvironmentObject var threadVM: ThreadViewModel

    var body: some View {
        VStack {
            ForEach(messages) { message in
                HStack {
                    if (message.message?.isEnglishString ?? false) == false {
                        Spacer()
                    }
                    Text(message.messageTitle)
                        .font(.iransansBody)

                    if message.message?.isEnglishString ?? false == true {
                        Spacer()
                    }
                    Button {
                        threadVM.unpinMessage(message.id ?? -1)
                    } label: {
                        Label("Un Pin", systemImage: "pin.fill")
                            .labelStyle(.iconOnly)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .frame(height: 48)
                .background(.regularMaterial)
                .onTapGesture {
                    if let time = message.time, let messageId = message.id {
                        threadVM.moveToTime(time, messageId)
                    }
                }
            }
            Spacer()
        }
        .animation(.easeInOut, value: messages.count)
    }
}

struct ThreadPinMessage_Previews: PreviewProvider {
    static var previews: some View {
        ThreadPinMessage()
    }
}
