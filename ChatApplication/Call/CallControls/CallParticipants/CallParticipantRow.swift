//
//  CallParticipantRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct CallParticipantRow: View {
	
	private (set) var participant:CallParticipant
	private var viewModel:CallParticipantsViewModel

	init(participant: CallParticipant , viewModel:CallParticipantsViewModel) {
		self.participant = participant
		self.viewModel = viewModel
	}
	
	var body: some View {
        
		Button(action: {}, label: {
			HStack{
                Avatar(url:participant.participant?.image ?? "" ,userName: participant.participant?.username ?? "", fileMetaData: nil)
				VStack(alignment: .leading, spacing:8){
                    Text(participant.participant?.name ?? "")
						.font(.headline)
					#if DEBUG
                    Text("participantId:\(String(participant.participant?.id ?? 0))")
					#endif
				}
				Spacer()
                Circle()
                    .fill(participant.mute ? Color.gray : .green)
                    .shadow(color: .gray, radius: 5, x: 0, y: 0)
                    .overlay(
                        Image(systemName: participant.mute ? "mic.slash.fill" : "mic.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.white)
                            .padding(2)
                    )
                    .frame(width: 32 , height: 32)
			}
			.contentShape(Rectangle())
			.padding([.leading , .trailing] , 8)
			.padding([.top , .bottom] , 4)
            .background(Color.white)
            .cornerRadius(16)
		})
	}
}

struct CallParticipantRow_Previews: PreviewProvider {
	static var callParticipant:CallParticipant{
        let participant = ParticipantRow_Previews.participant
        let callParticipant = CallParticipant(joinTime: 0, leaveTime: 0, userId: 0, sendTopic: "", receiveTopic: "", active: true, callStatus: .ACCEPTED,mute: true,video: false,participant: participant)
		return callParticipant
	}
	
	static var previews: some View {
        CallParticipantRow(participant: callParticipant, viewModel: CallParticipantsViewModel())
	}
}
