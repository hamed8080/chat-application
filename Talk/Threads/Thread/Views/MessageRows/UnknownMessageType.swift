//
//  UnknownMessageType.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import SwiftUI
import TalkUI
import Chat
import TalkModels

struct UnknownMessageType: View {
    let message: any HistoryMessageProtocol

    var body: some View {
        if EnvironmentValues.isTalkTest {
            VStack {
                Text("something is wrong")
                Rectangle()
                    .fill(Color.App.color2)
            }
        } else {
            EmptyView()
                .frame(height: 0)
                .padding(0)
                .hidden()
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        UnknownMessageType(message: Message())
    }
}
