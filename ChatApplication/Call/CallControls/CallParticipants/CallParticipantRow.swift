//
//  CallParticipantRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct CallParticipantRow: View {
    var participant: CallParticipant

    @EnvironmentObject
    var viewModel: CallParticipantsViewModel

    var body: some View {
        HStack {
            Avatar(url: participant.participant?.image ?? "", userName: participant.participant?.username ?? "")
            VStack {
                Text(participant.title ?? "")
                    .font(.headline)

                HStack(spacing: 0) {
                    if participant.canRecall {
                        Button {
                            viewModel.recall(participant)
                        } label: {
                            Image(systemName: "phone.fill.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .padding(8)
                        }
                    }

                    if let callStatusString = participant.callStatusString {
                        Text(callStatusString)
                            .foregroundColor(participant.callStatusStringColor)
                            .font(.caption.bold())
                    }
                }
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
                .frame(width: 32, height: 32)
        }
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 4)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct CallParticipantRow_Previews: PreviewProvider {

    static var previews: some View {
        let viewModel = CallParticipantsViewModel(callId: 1)
        let callParticipants = MockData.generateCallParticipant(count: 1, callStatus: .accepted)
        CallParticipantRow(participant: callParticipants.first!)
            .environmentObject(viewModel)
            .onAppear {                
                viewModel.callParticipants = callParticipants
                viewModel.objectWillChange.send()
            }
    }
}
