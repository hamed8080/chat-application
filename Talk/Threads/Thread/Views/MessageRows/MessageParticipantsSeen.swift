//
//  MessageParticipantsSeen.swift
//  Talk
//
//  Created by hamed on 11/15/23.
//

import SwiftUI
import TalkViewModels
import ChatModels
import TalkUI

struct MessageParticipantsSeen: View {
    @StateObject var viewModel: MessageParticipantsSeenViewModel
    init(message: Message) {
        self._viewModel = StateObject(wrappedValue: .init(message: message))
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack {
                ForEach(viewModel.participants) { participant in
                    MessageSeenParticipantRow(participant: participant)
                        .onAppear {
                            if participant == viewModel.participants.last {
                                viewModel.loadMore()
                            }
                        }
                }
            }
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .background(Color.App.bgPrimary)
        .animation(.easeInOut, value: viewModel.participants.count)
        .padding(.horizontal, 6)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("SeenParticipants.title")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: MessageParticipantsSeenNavigationValue.self)
                }
            }

            ToolbarItemGroup(placement: .principal) {
                Text("SeenParticipants.title")
                    .font(.iransansBoldBody)
                    .foregroundStyle(Color.App.text)
            }
        }
        .onAppear {
            viewModel.getParticipants()
        }
    }
}

struct MessageSeenParticipantRow: View {
    let participant: Participant

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: participant.image, userName: participant.name ?? participant.username)
                .id("\(participant.image ?? "")\(participant.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.App.blue.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius:(22)))

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
            }
        }
        .lineLimit(1)
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
    }
}

struct MessageParticipantsSeen_Previews: PreviewProvider {
    static var previews: some View {
        MessageParticipantsSeen(message: .init(id: 1))
    }
}
