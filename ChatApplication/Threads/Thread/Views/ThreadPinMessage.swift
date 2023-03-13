//
//  ThreadPinMessage.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import FanapPodChatSDK
import SwiftUI

struct ThreadPinMessage: View {
    private var messages: [Message] { threadVM.thread?.pinMessages ?? [] }
    @EnvironmentObject var threadVM: ThreadViewModel

    var body: some View {
        VStack {
            ForEach(messages) { message in
                HStack {
                    Text(message.messageTitle)
                    Spacer()
                    Button {
                        threadVM.unpin(message.id ?? -1)
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
                    threadVM.setScrollToUniqueId(message.uniqueId ?? "")
                }
            }
            Spacer()
        }
    }
}

struct ThreadPinMessage_Previews: PreviewProvider {
    static var previews: some View {
        ThreadPinMessage()
    }
}
