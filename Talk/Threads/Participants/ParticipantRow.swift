//
//  ParticipantRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatModels
import Combine
import SwiftUI
import TalkUI
import TalkViewModels

struct ParticipantRow: View {
    let participant: Participant

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: participant.image, userName: participant.name ?? participant.username)
                .id("\(participant.image ?? "")\(participant.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(22)

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                        .font(.iransansBody)
                    if let cellphoneNumber = participant.cellphoneNumber, !cellphoneNumber.isEmpty {
                        Text(cellphoneNumber)
                            .font(.iransansCaption3)
                            .foregroundColor(.primary.opacity(0.5))
                    }
                    if  let notSeenDuration = participant.notSeenString {
                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"))
                        let time = String(format: lastVisitedLabel, notSeenDuration)
                        Text(time)
                            .font(.iransansBody)
                            .foregroundColor(Color.hint)
                    }
                }

                Spacer()
                ParticipantRowLables(participantId: participant.id)
            }
        }
        .lineLimit(1)
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 12)
        .padding([.top, .bottom], 6)
    }
}

struct ParticipantRowLables: View {
    /// It is essential to use the ViewModel version of the participant rather than pass it to the view as a `let participant`. It is needed when an add/remove admin or assistant access is updated.
    @EnvironmentObject var viewModel: ParticipantsViewModel
    var paritcipant: Participant? { viewModel.participants.first(where: { $0.id == participantId })  }
    @State var participantId: Int?

    var body: some View {
        HStack {
            if let participant = paritcipant {
                if AppState.shared.user?.id != participant.id, participant.conversation?.inviter?.id == participantId {
                    Text("Participant.inviter")
                        .padding([.leading, .trailing], 4)
                        .padding([.top, .bottom], 2)
                        .foregroundColor(Color.main)
                }

                if participant.auditor == true {
                    Text("Participant.assistant")
                        .padding([.leading, .trailing], 4)
                        .padding([.top, .bottom], 2)
                        .foregroundColor(Color.main)
                }

                if participant.admin == true {
                    Text("Participant.admin")
                        .padding([.leading, .trailing], 4)
                        .padding([.top, .bottom], 2)
                        .foregroundColor(Color.main)
                }
            }
        }
        .font(.iransansCaption)
    }
}

struct ParticipantRow_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantRow(participant: MockData.participant(1))
    }
}
