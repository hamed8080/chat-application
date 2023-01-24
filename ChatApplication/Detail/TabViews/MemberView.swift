//
//  MemberView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import FanapPodChatSDK
import SwiftUI

struct MemberView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        ListLoadingView(isLoading: $viewModel.isLoading)
        ParticipantSearchView()
        ForEach(viewModel.filtered) { participant in
            ParticipantRow(participant: participant)
                .onAppear {
                    if viewModel.participants.last == participant {
                        viewModel.loadMore()
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.removePartitipant(participant)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .animation(.easeInOut, value: viewModel.filtered.count)
        .animation(.easeInOut, value: viewModel.participants.count)
        .animation(.easeInOut, value: viewModel.searchText)
        .animation(.easeInOut, value: viewModel.isLoading)
        .ignoresSafeArea(.all)
    }
}

enum SearchParticipantType: String, CaseIterable, Identifiable {
    var id: Self { self }
    case name = "Name"
    case username = "User Name"
    case cellphoneNumber = "Mobile"
    case admin = "Admin"
}

struct ParticipantSearchView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel
    @State var type: SearchParticipantType = .name
    @State var searchText: String = ""
    var body: some View {
        HStack {
            Picker("", selection: $type) {
                ForEach(SearchParticipantType.allCases) { item in
                    Text(item.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .layoutPriority(0)

            TextField("Search for users in thread", text: $searchText)
                .textFieldStyle(.customBorderedWith(minHeight: 24, cornerRadius: 12))
                .frame(maxWidth: 420)
                .layoutPriority(1)
                .onChange(of: searchText) { newValue in
                    viewModel.searchParticipants(text: newValue, type: type)
                }
            Spacer()
        }
        .animation(.easeInOut, value: searchText)
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
