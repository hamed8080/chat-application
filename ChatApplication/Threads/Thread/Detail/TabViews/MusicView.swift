//
//  MusicView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import SwiftUI
import FanapPodChatSDK

struct MusicView: View {
    
    var thread:Conversation
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct MusicView_Previews: PreviewProvider {
    static var previews: some View {
        MusicView(thread: ThreadRow_Previews.thread)
    }
}
