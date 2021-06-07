//
//  ThreadRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct ThreadRow: View {
    
    private (set) var thread:Conversation
    
    init(thread: Conversation) {
        self.thread = thread
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16, content: {
            Avatar(url:thread.image ,userName: thread.inviter?.firstName, fileMetaData: thread.metadata)
            VStack(alignment: .leading, spacing:8){
                Text(thread.title ?? "")
                    .font(.headline)
                if let message = thread.lastMessageVO?.message?.prefix(100){
                    Text(message)
                        .lineLimit(2)
                        .font(.subheadline)
                }
            }
            Spacer()
            if let unreadCount = thread.unreadCount ,let unreadCountString = String(unreadCount){
                let isCircle = unreadCount < 10 // two number and More require oval shape
                let computedString = unreadCount < 1000 ? unreadCountString : "\(unreadCount / 1000)K+"
                Text(computedString)
                    .font(.system(size: 13))
                    .padding(8)
                    .frame(height: 24)
                    .frame(minWidth:24)
                    .foregroundColor(Color.white)
                    .background(Color.orange)
                    .cornerRadius(isCircle ? 16 : 8, antialiased: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
            }
        })
        .padding([.leading , .trailing] , 8)
        .padding([.top , .bottom] , 4)
    }
}

struct ThreadRow_Previews: PreviewProvider {
    static var thread:Conversation{
        let lastMessageVO = Message(threadId: nil, deletable: nil, delivered: nil, editable: nil, edited: nil, id: nil, mentioned: nil, message: "Hi hamed how are you? are you ok? and what are you ding now. And i was thinking you are sad for my behavoi last night.", messageType: nil, metadata: nil, ownerId: nil, pinned: nil, previousId: nil, seen: nil, systemMetadata: nil, time: nil, timeNanos: nil, uniqueId: nil, conversation: nil, forwardInfo: nil, participant: nil, replyInfo: nil)
        let thread = Conversation(admin: false, canEditInfo: true, canSpam: true, closedThread: false, description: "des", group: true, id: 123, image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png", joinDate: nil, lastMessage: nil, lastParticipantImage: nil, lastParticipantName: nil, lastSeenMessageId: nil, lastSeenMessageNanos: nil, lastSeenMessageTime: nil, mentioned: nil, metadata: nil, mute: nil, participantCount: nil, partner: nil, partnerLastDeliveredMessageId: nil, partnerLastDeliveredMessageNanos: nil, partnerLastDeliveredMessageTime: nil, partnerLastSeenMessageId: nil, partnerLastSeenMessageNanos: nil, partnerLastSeenMessageTime: nil, pin: nil, time: nil, title: "Hamed Hosseini", type: nil, unreadCount: 3000, uniqueName: nil, userGroupHash: nil, inviter: nil, lastMessageVO: lastMessageVO, participants: nil, pinMessage: nil)
        return thread
    }
    
    static var previews: some View {
        ThreadRow(thread: thread)
    }
}
