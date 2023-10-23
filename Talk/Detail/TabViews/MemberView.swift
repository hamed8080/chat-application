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
        ParticipantSearchView()
            .padding(.top)
        LazyVStack(spacing: 0) {
            if viewModel.searchedParticipants.count > 0 {
                StickyHeaderSection(header: "Memebers.searchedMembers")
                ForEach(viewModel.searchedParticipants) { participant in
                    ParticipantRowContainer(participant: participant, isSearchRow: true)
                }
            }

            StickyHeaderSection(header: "Tab.contacts")
            AddParticipantButton(conversation: viewModel.thread)
                .listRowSeparatorTint(.gray.opacity(0.2))
                .listRowBackground(Color.bgColor)
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
            return viewModel.participants.last == participant ? Color.clear : Color.dividerDarkerColor.opacity(0.3)
        } else {
            return viewModel.searchedParticipants.last == participant ? Color.clear : Color.dividerDarkerColor.opacity(0.3)
        }
    }

    var body: some View {
        ParticipantRow(participant: participant)
            .id("\(isSearchRow ? "SearchRow" : "Normal")\(participant.id ?? 0)")
            .padding(.vertical)
            .background(Color.bgColor)
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
        Button {
            presentSheet.toggle()
        } label: {
            HStack(spacing: 24) {
                Image(systemName: "person.crop.circle.fill.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 16)
                    .foregroundStyle(Color.main)
                Text("Thread.invite")
                    .font(.iransansBody)
                Spacer()
            }
            .foregroundStyle(Color.main)
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
        HStack {
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
            }
            .frame(width: 128)

            TextField("General.searchHere", text: $viewModel.searchText)
                .textFieldStyle(.customBorderedWith(minHeight: 24, cornerRadius: 12))
                .frame(minWidth: 0, maxWidth: 420)
            Spacer()
        }
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
        .environmentObject(viewModel)
        .onAppear {
            viewModel.appendParticipants(participants: MockData.generateParticipants())
        }
    }
}
