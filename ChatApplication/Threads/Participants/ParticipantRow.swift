//
//  ParticipantRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct ParticipantRow: View {
	
	private (set) var participant:Participant
	private var viewModel:ParticipantsViewModel

	init(participant: Participant , viewModel:ParticipantsViewModel) {
		self.participant = participant
		self.viewModel = viewModel
	}
	
	var body: some View {
		
		Button(action: {}, label: {
			HStack{
				Avatar(url:participant.image ,userName: participant.username, fileMetaData: nil)
				VStack(alignment: .leading, spacing:8){
					Text(participant.name ?? "")
						.font(.headline)
					#if DEBUG
						Text("participantId:\(participant.id ?? 0)")
					#endif
				}
				Spacer()
			}
			.contentShape(Rectangle())
			.padding([.leading , .trailing] , 8)
			.padding([.top , .bottom] , 4)
		})
	}
}

struct ParticipantRow_Previews: PreviewProvider {
	static var participant:Participant{
		let participant = Participant(admin: true, auditor: nil, blocked: false, cellphoneNumber: "+989369161601", contactFirstName: "Hamed", contactId: nil, contactName: "Hamed", contactLastName: "Hosseini", coreUserId: nil, email: nil, firstName: "Hamed", id: 123, image: nil, keyId: nil, lastName: "Hosseini", myFriend: true, name: "Hamed", notSeenDuration: 0, online: true, receiveEnable: true, roles: nil, sendEnable: true, username: "hamed8080", chatProfileVO: nil)
		return participant
	}
	
	static var previews: some View {
		ParticipantRow(participant: participant, viewModel: ParticipantsViewModel())
	}
}
