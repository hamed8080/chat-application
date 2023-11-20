//
//  AssistantView.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import ChatCore
import ChatDTO
import ChatModels
import Logger
import SwiftUI
import TalkUI
import TalkViewModels

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
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut, value: viewModel.assistants.count)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: AssistantNavigationValue.self)
                }
            }

            ToolbarItemGroup {
                Button {
                    viewModel.deactiveSelectedAssistants()
                } label: {
                    Label("General.delete", systemImage: "trash")
                }
                .foregroundStyle(.red)
                .opacity(viewModel.selectedAssistant.count == 0 ? 0.2 : 1)
                .disabled(viewModel.selectedAssistant.count == 0)

                Button {
                    viewModel.showAddAssistantSheet = true
                } label: {
                    Label("General.add", systemImage: "plus")
                }

                Button {
                    withAnimation {
                        viewModel.isInSelectionMode.toggle()
                    }
                } label: {
                    Label("General.select", systemImage: "filemenu.and.selection")
                }
                .disabled(viewModel.assistants.count == 0)

                Menu {
                    NavigationLink(value: Assistant()) {
                        Label("Assistant.histories", systemImage: "clock")
                    }

                    NavigationLink(value: BlockedAssistantsRequest()) {
                        Label("Assistant.blockedList", systemImage: "hand.raised")
                    }
                } label: {
                    Label("General.more", systemImage: "ellipsis.circle")
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
                    SectionTitleView(title: String(localized: .init("Assistant.selectAssistant")))
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
                .background(Color.App.blue.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius:(12)))
            VStack(alignment: .leading, spacing: 4) {
                Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                    .padding(.leading, 4)
                    .lineLimit(1)
                    .font(.iransansSubheadline)
                Text(String(localized: .init(contact.notSeenDuration?.localFormattedTime ?? "General.notSpecified")))
                    .padding(.leading, 4)
                    .font(.iransansCaption3)
                    .foregroundColor(Color.App.gray1)
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
