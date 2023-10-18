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
        LazyVStack(spacing: 0) {
            AddParticipantButton(conversation: viewModel.thread)
                .listRowSeparatorTint(.gray.opacity(0.2))
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
            AddParticipantsToThreadView(viewModel: .init()) { contacts in
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
        List {
            MemberView()
        }
        .environmentObject(viewModel)
        .onAppear {
            viewModel.appendParticipants(participants: MockData.generateParticipants())
        }
    }
}
