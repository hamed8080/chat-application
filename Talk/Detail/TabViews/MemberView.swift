//
//  MemberView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels
import ChatModels
import ChatDTO

struct MemberView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        StickyHeaderSection(header: "", height: 4)
        AddParticipantButton(conversation: viewModel.thread)
            .listRowSeparatorTint(.gray.opacity(0.2))
            .listRowBackground(Color.App.bgPrimary)
        ParticipantSearchView()
        LazyVStack(spacing: 0) {
            if viewModel.searchedParticipants.count > 0 {
                StickyHeaderSection(header: "Memebers.searchedMembers")
                ForEach(viewModel.searchedParticipants) { participant in
                    ParticipantRowContainer(participant: participant, isSearchRow: true)
                }
            }

            ForEach(viewModel.sorted) { participant in
                ParticipantRowContainer(participant: participant, isSearchRow: false)
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: viewModel.participants.count)
        .animation(.easeInOut, value: viewModel.searchedParticipants.count)
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

struct ParticipantRowContainer: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel
    let participant: Participant
    let isSearchRow: Bool
    var separatorColor: Color {
        if !isSearchRow {
            return viewModel.participants.last == participant ? Color.clear : Color.App.divider
        } else {
            return viewModel.searchedParticipants.last == participant ? Color.clear : Color.App.divider
        }
    }

    var body: some View {
        ParticipantRow(participant: participant)
            .id("\(isSearchRow ? "SearchRow" : "Normal")\(participant.id ?? 0)")
            .padding(.vertical)
            .background(Color.App.bgPrimary)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(separatorColor)
                    .frame(height: 0.5)
                    .padding(.leading, 64)
            }
            .onAppear {
                if viewModel.participants.last == participant {
                    viewModel.loadMore()
                }
            }
            .onTapGesture {
                if participant.id != AppState.shared.user?.id {
                    AppState.shared.openThread(participant: participant)
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

                if viewModel.thread?.admin == true {
                    Button(role: .destructive) {
                        viewModel.removePartitipant(participant)
                    } label: {
                        Label("General.delete", systemImage: "trash")
                    }
                }
            }
    }
}

struct AddParticipantButton: View {
    @State var presentSheet: Bool = false
    let conversation: Conversation?

    var body: some View {
        if conversation?.group == true, conversation?.admin == true{
            Button {
                presentSheet.toggle()
            } label: {
                HStack(spacing: 24) {
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 16)
                        .foregroundStyle(Color.App.primary)
                    Text("Thread.invite")
                        .font(.iransansBody)
                    Spacer()
                }
                .foregroundStyle(Color.App.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .sheet(isPresented: $presentSheet) {
                AddParticipantsToThreadView() { contacts in
                    addParticipantsToThread(contacts)
                    presentSheet.toggle()
                }
            }
        }
    }

    public func addParticipantsToThread(_ contacts: [Contact]) {
        guard let threadId = conversation?.id else { return }
        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)
        ChatManager.activeInstance?.conversation.participant.add(req)        
    }
}

struct ParticipantSearchView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(SearchParticipantType.allCases) { item in
                    Button {
                        withAnimation {
                            viewModel.searchType = item
                        }
                    } label: {
                        Text(String(localized: .init(item.rawValue)))
                            .font(.iransansBoldCaption3)
                    }
                }
            } label: {
                Text(String(localized: .init(viewModel.searchType.rawValue)))
                    .font(.iransansBoldCaption3)
                    .foregroundColor(Color.App.primary)
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.App.hint)
                    .frame(width: 16, height: 16)
                TextField("General.searchHere", text: $viewModel.searchText)
                    .frame(minWidth: 0, maxWidth: 420)
                    .font(.iransansBody)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color.App.separator)
        .animation(.easeInOut, value: viewModel.searchText)
        .animation(.easeInOut, value: viewModel.searchType)
    }
}

struct MemberView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ParticipantsViewModel(thread: MockData.thread)
        List {
            MemberView()
        }
        .listStyle(.plain)
        .environmentObject(viewModel)
        .onAppear {
            viewModel.appendParticipants(participants: MockData.generateParticipants())
        }
    }
}
