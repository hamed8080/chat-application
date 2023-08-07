//
//  AssistantView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatCore
import ChatDTO
import ChatModels
import Logger
import SwiftUI

struct AssistantView: View {
    @StateObject var viewModel: AssistantViewModel = .init()

    var body: some View {
        List {
            ForEach(viewModel.assistants) { assistant in
                AssistantRow(assistant: assistant)
            }
            .onDelete(perform: viewModel.deactive)
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .environmentObject(viewModel)
        .navigationTitle("Assistants")
        .animation(.easeInOut, value: viewModel.assistants.count)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.deactiveSelectedAssistants()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundStyle(.red)
                .opacity(viewModel.selectedAssistant.count == 0 ? 0.2 : 1)
                .disabled(viewModel.selectedAssistant.count == 0)

                Button {
                    viewModel.showAddAssistantSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }

                Button {
                    withAnimation {
                        viewModel.isInSelectionMode.toggle()
                    }
                } label: {
                    Label {
                        Text("Selection")
                    } icon: {
                        Image(systemName: "filemenu.and.selection")
                    }
                }
                .disabled(viewModel.assistants.count == 0)

                Menu {
                    NavigationLink(value: Assistant()) {
                        Label("Histories", systemImage: "clock")
                    }

                    NavigationLink(value: BlockedAssistantsRequest()) {
                        Label("Blocked Assistants", systemImage: "hand.raised")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .navigationDestination(for: Assistant.self) { _ in
            AssistantHistoryView()
        }
        .navigationDestination(for: BlockedAssistantsRequest.self) { _ in
            BlockedAssistantsView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showAddAssistantSheet) {
            PickAssitstantListView()
                .environmentObject(viewModel)
        }
    }
}

struct PickAssitstantListView: View {
    @EnvironmentObject var viewModel: AssistantViewModel
    @StateObject var contactsVM = ContactsViewModel()

    var body: some View {
        NavigationView {
            Form {
                List {
                    SectionTitleView(title: "Select your assistant")
                    SectionImageView(image: Image(systemName: "figure.stand.line.dotted.figure.stand"))
                    ForEach(contactsVM.contacts) { contact in
                        AddAssistantRow(contact: contact)
                            .onTapGesture {
                                viewModel.registerAssistant(contact)
                                viewModel.showAddAssistantSheet = false
                            }
                            .onAppear {
                                if contactsVM.contacts.last == contact {
                                    contactsVM.loadMore()
                                }
                            }
                    }
                }
            }
        }
    }
}

struct AddAssistantRow: View {
    let contact: Contact
    @StateObject var imageViewModel = ImageLoaderViewModel()

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: imageViewModel, url: contact.image ?? contact.user?.image, userName: contact.firstName)
                .id("\(contact.image ?? "")\(contact.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                    .padding(.leading, 4)
                    .lineLimit(1)
                    .font(.headline)
                Text(contact.notSeenString ?? "Not specified.")
                    .padding(.leading, 4)
                    .font(.iransansCaption3)
                    .foregroundColor(Color.gray)
            }
        }
    }
}

struct AssistantView_Previews: PreviewProvider {
    static var viewModel = AssistantViewModel()
    static var assistant: Assistant {
        let participant = Participant(name: "Hamed Hosseini")
        let roles: [Roles] = [.addNewUser, .editThread, .editMessageOfOthers]
        return Assistant(id: 1, participant: participant, roles: roles, block: true)
    }

    static var previews: some View {
        AssistantView(viewModel: viewModel)
            .onAppear {
                let response: ChatResponse<[Assistant]> = .init(uniqueId: UUID().uuidString, result: [assistant])
                viewModel.onAssistants(response)
            }
    }
}
