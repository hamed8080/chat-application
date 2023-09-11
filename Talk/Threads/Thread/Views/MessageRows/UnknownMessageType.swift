//
//  UnknownMessageType.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import ChatModels
import SwiftUI

struct UnknownMessageType: View {
    let message: Message

    var body: some View {
        #if DEBUG
            VStack {
                Text("something is wrong")
                Rectangle()
                    .fill(Color.green)
            }
        #else
            EmptyView()
                .frame(height: 0)
                .padding(0)
                .hidden()
        #endif
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        UnknownMessageType(message: Message())
    }
}
