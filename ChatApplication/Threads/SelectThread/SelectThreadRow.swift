//
//  SelectThreadRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct SelectThreadRow: View {
	
	var thread:Conversation
	
    var body: some View {
        let token = TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken
        HStack{
            Avatar(
                url: thread.image,
                userName: thread.inviter?.username?.uppercased(),
                style: .init(size: 36, textSize: 12),
                metadata: thread.metadata,
                token: token
            )
            Text(thread.title ?? "")
                .font(.headline)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding([.leading , .trailing] , 8)
        .padding([.top , .bottom] , 4)
    }
}

struct SelectThreadRow_Previews: PreviewProvider {
	static var previews: some View {
        SelectThreadRow(thread: MockData.thread)
	}
}
