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
    var isOnline: Bool { participant.notSeenDuration ?? 16000 < 15000 }

    var body: some View {
        HStack {
            ZStack {
                let config = ImageLoaderConfig(url: participant.image ?? "", userName: participant.name ?? participant.username)
                ImageLoaderView(imageLoader: .init(config: config))
                    .id("\(participant.image ?? "")\(participant.id ?? 0)")
                    .font(.iransansBoldBody)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.App.blue.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius:(22)))

                Circle()
                    .fill(Color.App.green)
                    .frame(width: 13, height: 13)
                    .offset(x: -20, y: 18)
                    .blendMode(.destinationOut)
                    .overlay {
                        Circle()
                            .fill(isOnline ? Color.App.green : Color.App.gray5)
                            .frame(width: 10, height: 10)
                            .offset(x: -20, y: 18)
                    }
            }
            .compositingGroup()

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                        .font(.iransansBody)
                    if let cellphoneNumber = participant.cellphoneNumber, !cellphoneNumber.isEmpty {
                        Text(cellphoneNumber)
                            .font(.iransansCaption3)
                            .foregroundColor(.primary.opacity(0.5))
                    }
                    if  let notSeenDuration = participant.notSeenDuration?.localFormattedTime {
                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"))
                        let time = String(format: lastVisitedLabel, notSeenDuration)
                        Text(time)
                            .font(.iransansBody)
                            .foregroundColor(Color.App.hint)
                    }
                }

                Spacer()
                ParticipantRowLables(participantId: participant.id)
            }
        }
        .lineLimit(1)
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
    }
}

struct ParticipantRowLables: View {
    /// It is essential to use the ViewModel version of the participant rather than pass it to the view as a `let participant`. It is needed when an add/remove admin or assistant access is updated.
    @EnvironmentObject var viewModel: ParticipantsViewModel
    var paritcipant: Participant? { viewModel.participants.first(where: { $0.id == participantId }) ?? viewModel.searchedParticipants.first(where: { $0.id == participantId })  }
    @State var participantId: Int?

    var body: some View {
        HStack {
            if let participant = paritcipant {
                if viewModel.thread?.inviter?.id == participantId {
                    Text("Participant.owner")
                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                        .foregroundColor(Color.App.primary)
                } else if participant.admin == true {
                    Text("Participant.admin")
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 4))
                        .foregroundColor(Color.App.primary)
                } else if participant.auditor == true {
                    Text("Participant.assistant")
                        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 4))
                        .foregroundColor(Color.App.primary)
                }
            }
        }
        .font(.iransansBoldCaption)
    }
}

struct ParticipantRow_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantRow(participant: MockData.participant(1))
    }
}
