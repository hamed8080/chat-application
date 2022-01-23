//
//  TagRow.swift
//  TagParticipantRow
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct TagParticipantRow: View {
	
	var tag:Tag
    var tagParticipant:TagParticipant
    
    @StateObject var viewModel:TagsViewModel
    
    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing:8){
                HStack{
                    let token = TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken
                    if let thread = tagParticipant.conversation{
                        Avatar(url:thread.image,
                               userName: thread.inviter?.username?.uppercased(),
                               fileMetaData: thread.metadata,
                               style: .init(size: 28, textSize: 12),
                               token: token)
                        
                        VStack(alignment:.leading){
                            Text(thread.title ?? "")
                                .font(.headline)
                                .foregroundColor(Color.gray)
                        }
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .padding([.leading , .trailing] , 8)
        .padding([.top , .bottom] , 4)
        .customAnimation(.default)
    }
}

struct TagParticipantRow_Previews: PreviewProvider {
	
    static func getTagParticipants(count:Int = 5)->[TagParticipant]{
        var tagParticipants:[TagParticipant] = []
        for index in 0...count{
            tagParticipants.append(.init(id: index, active: true, tagId: index, threadId: index, conversation: ThreadRow_Previews.thread))
        }
        return tagParticipants
    }
    
	static var previews: some View {
        TagParticipantRow(tag: TagRow_Previews.tag, tagParticipant: TagRow_Previews.tag.tagParticipants!.first! ,viewModel: TagsViewModel())
	}
}
