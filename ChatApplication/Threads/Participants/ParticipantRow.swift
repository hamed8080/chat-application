//
//  ParticipantRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import Combine
import SwiftUI

struct ParticipantRow: View {
    let participant: Participant
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        VStack {
            HStack {
                ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: participant.image, userName: participant.name ?? participant.username)
                    .id("\(participant.image ?? "")\(participant.id ?? 0)")
                    .font(.system(size: 16).weight(.heavy))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(24)

                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                            .font(.iransansBody)
                        if let cellphoneNumber = participant.cellphoneNumber, !cellphoneNumber.isEmpty {
                            Text(cellphoneNumber)
                                .font(.iransansCaption3)
                                .foregroundColor(.primary.opacity(0.5))
                        }
                        if participant.online == true {
                            Text("Participant.online")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }

                    ParticipantRowLables(participant: participant)
                }
                Spacer()
            }
            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(height: 0.5)
        }
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 12)
        .padding([.top, .bottom], 6)
    }
}

struct ParticipantRowLables: View {
    let participant: Participant
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        HStack {
            Spacer()

            if viewModel.thread?.inviter?.id == participant.id, AppState.shared.user?.id != participant.id {
                Text("Participant.inviter")
                    .padding([.leading, .trailing], 4)
                    .padding([.top, .bottom], 2)
                    .foregroundColor(.orange)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.orange, lineWidth: 1)
                    )
            }

            if participant.auditor == true {
                Text("Participant.assistant")
                    .padding([.leading, .trailing], 4)
                    .padding([.top, .bottom], 2)
                    .foregroundColor(.green)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.green, lineWidth: 1)
                    )
            }

            if participant.admin == true {
                Text("Participant.admin")
                    .padding([.leading, .trailing], 4)
                    .padding([.top, .bottom], 2)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
        }
        .font(.subheadline)
    }
}

struct ParticipantRow_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantRow(participant: MockData.participant(1))
    }
}
