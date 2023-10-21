//
//  CreateGroup.swift
//  Talk
//
//  Created by hamed on 10/19/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import PhotosUI

struct CreateGroup: View {
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        List {
            if viewModel.searchedContacts.count > 0 {
                Section {
                    ForEach(viewModel.searchedContacts) { contact in
                        SearchContactRow(contact: contact)
                            .listRowSeparatorTint(Color.dividerDarkerColor)
                            .listRowBackground(Color.bgColor)
                    }
                    .padding()
                } header: {
                    StickyHeaderSection(header: "Contacts.searched")
                }
                .listRowInsets(.zero)
            }

            Section {
                ForEach(viewModel.contacts) { contact in
                    ContactRow(isInSelectionMode: .constant(true), contact: contact)
                        .listRowBackground(Color.bgColor)
                        .listRowSeparatorTint(Color.dividerDarkerColor)
                        .onAppear {
                            if viewModel.contacts.last == contact {
                                viewModel.loadMore()
                            }
                        }
                }
                .onDelete(perform: viewModel.delete)
                .padding()
            } header: {
                StickyHeaderSection(header: "Contacts.selectContacts")
            }
            .listRowInsets(.zero)

            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.bgColor)
                .listRowSeparator(.hidden)
        }
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .overlay(alignment: .bottom) {
            SubmitBottomButton(text: "Contacts.createGroup",
                               enableButton: .constant(enabeleButton),
                               isLoading: $viewModel.isLoading)
            {
                viewModel.createGroupWithSelectedContacts()
            }
        }
        .sheet(isPresented: $viewModel.showEditCreatedGroupDetail) {
            EditCreatedGroupDetail()
        }
    }

    private var enabeleButton: Bool {
        viewModel.selectedContacts.count > 1 && !viewModel.isLoading
    }
}


/// Step two to edit title and picture of the group.
struct EditCreatedGroupDetail: View {
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
                                    .foregroundStyle(Color.hint)
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

                TextField("CreateGroup.enterGroupName", text: $viewModel.editTitle)
                    .textContentType(.name)
                    .padding()
                    .font(.iransansBody)
            }
            .frame(height: 88)
            .listRowBackground(Color.bgColor)
            .listRowSeparator(.hidden)
            Section {
                ForEach(viewModel.createdGroupParticpnats) { participant in
                    ParticipantRow(participant: participant)
                        .listRowBackground(Color.bgColor)
                        .listRowSeparatorTint(Color.dividerDarkerColor)
                }
                .onDelete(perform: viewModel.delete)
                .padding()
            } header: {
                StickyHeaderSection(header: "Thread.Tabs.members")
            }
            .listRowInsets(.zero)

            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.bgColor)
                .listRowSeparator(.hidden)
        }
        .background(Color.bgColor)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .overlay(alignment: .bottom) {
            SubmitBottomButton(text: "Contacts.createGroup",
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
        EditCreatedGroupDetail()
            .environmentObject(ContactsViewModel())
            .previewDisplayName("EditCreatedGroupDetail")

        CreateGroup()
            .environmentObject(ContactsViewModel())
            .previewDisplayName("CreateGroup")
    }
}
