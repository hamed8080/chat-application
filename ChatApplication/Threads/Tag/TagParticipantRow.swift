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
                        Avatar(
                            url: thread.image,
                            userName: thread.inviter?.username?.uppercased(),
                            style: .init(size: 28, textSize: 12),
                            metadata: thread.metadata,
                            token: token
                        )
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
    }
}

struct TagParticipantRow_Previews: PreviewProvider {
	
	static var previews: some View {
        TagParticipantRow(tag: MockData.tag, tagParticipant: MockData.tag.tagParticipants!.first! ,viewModel: TagsViewModel())
	}
}
