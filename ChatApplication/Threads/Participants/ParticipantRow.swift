//
//  ParticipantRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

struct ParticipantRow: View {
    let participant: Participant

    var body: some View {
        Button(action: {}, label: {
            HStack {
                ImageLaoderView(url: participant.image, userName: participant.name ?? participant.username)
                    .font(.system(size: 16).weight(.heavy))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(24)

                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                            .font(.headline)
                        Text(participant.cellphoneNumber ?? "")
                            .font(.caption2)
                            .foregroundColor(.primary.opacity(0.5))
                        if participant.online == true {
                            Text("online")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }

                    if participant.admin == true {
                        Spacer()

                        Text("Admin")
                            .padding(4)
                            .foregroundColor(Color.blue)
                            .font(.headline)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding([.leading, .trailing], 8)
            .padding([.top, .bottom], 4)
        })
    }
}

struct ParticipantRow_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantRow(participant: MockData.participant)
    }
}
