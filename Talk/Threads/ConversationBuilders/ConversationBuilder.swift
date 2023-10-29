//
//  ConversationBuilder.swift
//  Talk
//
//  Created by hamed on 10/19/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import PhotosUI

struct ConversationBuilder: View {
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        List {
            if viewModel.searchedContacts.count > 0 {
                StickyHeaderSection(header: "Contacts.searched")
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
                ForEach(viewModel.searchedContacts) { contact in
                    ContactRowContainer(contact: contact, isSearchRow: true)
                }
                .padding()
                .listRowInsets(.zero)
            }

            StickyHeaderSection(header: "Contacts.selectContacts")
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            ForEach(viewModel.contacts) { contact in
                ContactRowContainer(contact: contact, isSearchRow: false)
                    .onAppear {
                        if viewModel.contacts.last == contact {
                            viewModel.loadMore()
                        }
                    }
            }
            .onDelete(perform: viewModel.delete)
            .padding()
            .listRowInsets(.zero)

            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 24)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 41)
        }
        .overlay(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("General.searchHere", text: $viewModel.searchContactString)
                    .frame(height: 48)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .frame(height: 48)
            .background(.ultraThinMaterial)
        }
        .overlay(alignment: .bottom) {
            SubmitBottomButton(text: viewModel.createConversationType == .normal ? "Contacts.createGroup" : "Contacts.createChannel",
                               enableButton: .constant(enabeleButton),
                               isLoading: $viewModel.isLoading)
            {
                viewModel.createGroupWithSelectedContacts()
            }
        }
        .sheet(isPresented: $viewModel.showEditCreatedConversationDetail) {
            EditCreatedConversationDetail()
        }
        .onAppear {
            /// We use ContactRowContainer view because it is essential to force the ineer contactRow View to show radio buttons.
            viewModel.isInSelectionMode = true
        }
        .onDisappear {
            withAnimation(.easeInOut(duration: 0.1)) {
                viewModel.isInSelectionMode = false
            }
        }
    }

    private var enabeleButton: Bool {
        viewModel.selectedContacts.count > 1 && !viewModel.isLoading
    }
}

/// Step two to edit title and picture of the group/channel....
struct EditCreatedConversationDetail: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    @State var showImagePicker = false

    var body: some View {
        List {
            HStack {
                Button {
                    showImagePicker.toggle()
                } label: {
                    ZStack {
                        Rectangle()
                            .fill(Color("bg_camera"))
                            .frame(width: 64, height: 64)
                            .cornerRadius(28)
                            .overlay(alignment: .center) {
                                Image(systemName: "camera.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundStyle(Color.App.hint)
                            }

                        /// Showing the image taht user has selected.
                        if let image = viewModel.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .cornerRadius(28)
                        }
                    }
                }
                .buttonStyle(.plain)

                TextField(viewModel.createConversationType == .normal ? "ConversationBuilder.enterGroupName" : "ConversationBuilder.enterChannelName" , text: $viewModel.conversationTitle)
                    .textContentType(.name)
                    .padding()
                    .font(.iransansBody)
            }
            .frame(height: 88)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparator(.hidden)
            Section {
                ForEach(viewModel.createdConversationParticpnats) { participant in
                    ParticipantRow(participant: participant)
                        .listRowBackground(Color.App.bgPrimary)
                        .listRowSeparatorTint(Color.App.divider)
                }
                .onDelete(perform: viewModel.delete)
                .padding()
            } header: {
                StickyHeaderSection(header: "Thread.Tabs.members")
            }
            .listRowInsets(.zero)

            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparator(.hidden)
        }
        .background(Color.App.bgPrimary)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .environmentObject(ParticipantsViewModel(thread: viewModel.createdConversation ?? .init()))
        .overlay(alignment: .bottom) {
            SubmitBottomButton(text: viewModel.createConversationType == .normal ? "Contacts.createGroup" : "Contacts.createChannel",
                               enableButton: .constant(!viewModel.isLoading),
                               isLoading: $viewModel.isLoading)
            {
                viewModel.submitEditCreatedGroup()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                self.viewModel.image = image
                self.viewModel.assetResources = assestResources ?? []
                self.viewModel.animateObjectWillChange()
                showImagePicker = false
            }
        }
    }
}

struct CreateGroup_Previews: PreviewProvider {
    static var previews: some View {
        ConversationBuilder()
            .environmentObject(ContactsViewModel())
            .previewDisplayName("CreateConversation")
        EditCreatedConversationDetail()
            .environmentObject(ContactsViewModel())
            .previewDisplayName("EditCreatedConversationDetail")
    }
}
