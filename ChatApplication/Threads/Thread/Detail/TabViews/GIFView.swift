//
//  GIFView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import FanapPodChatSDK
import SwiftUI

struct GIFView: View {
    var thread: Conversation

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct GIFView_Previews: PreviewProvider {
    static var previews: some View {
        GIFView(thread: MockData.thread)
    }
}
