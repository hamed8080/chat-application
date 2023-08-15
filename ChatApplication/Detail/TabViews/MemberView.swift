//
//  MemberView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatAppModels
import ChatAppUI
import ChatAppViewModels
import SwiftUI

struct MemberView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        ParticipantSearchView()
        LazyVStack(spacing: 0) {
            ForEach(viewModel.sorted) { participant in
                ParticipantRow(participant: participant)
                    .onAppear {
                        if viewModel.participants.last == participant {
                            viewModel.loadMore()
                        }
                    }
                    .contextMenu {
                        if viewModel.thread?.admin == true, (participant.admin ?? false) == false {
                            Button {
                                viewModel.makeAdmin(participant)
                            } label: {
                                Label("Participant.addAdminAccess", systemImage: "person.badge.key.fill")
                            }
                        }

                        if viewModel.thread?.admin == true, (participant.admin ?? false) == true {
                            Button {
                                viewModel.removeAdminRole(participant)
                            } label: {
                                Label("Participant.removeAdminAccess", systemImage: "person.crop.circle.badge.minus")
                            }
                        }

                        Button(role: .destructive) {
                            viewModel.removePartitipant(participant)
                        } label: {
                            Label("General.delete", systemImage: "trash")
                        }
                    }
            }
        }
        .animation(.easeInOut, value: viewModel.filtered.count)
        .animation(.easeInOut, value: viewModel.participants.count)
        .animation(.easeInOut, value: viewModel.searchText)
        .animation(.easeInOut, value: viewModel.isLoading)
        .ignoresSafeArea(.all)
        .padding(.bottom)
        .onAppear {
            if viewModel.participants.count == 0 {
                viewModel.getParticipants()
            }
        }
    }
}

struct ParticipantSearchView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        HStack {
            Picker("", selection: $viewModel.searchType) {
                ForEach(SearchParticipantType.allCases) { item in
                    Text(String(localized: .init(item.rawValue)))
                        .font(.iransansBoldCaption3)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .layoutPriority(0)
            .frame(width: 128)

            TextField("General.searchHere", text: $viewModel.searchText)
                .textFieldStyle(.customBorderedWith(minHeight: 24, cornerRadius: 12))
                .frame(minWidth: 0, maxWidth: 420)
                .layoutPriority(1)
            Spacer()
        }
        .animation(.easeInOut, value: viewModel.searchText)
        .animation(.easeInOut, value: viewModel.searchType)
    }
}

struct MemberView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ParticipantsViewModel(thread: MockData.thread)
        MemberView()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.appendParticipants(participants: MockData.generateParticipants())
            }
    }
}
