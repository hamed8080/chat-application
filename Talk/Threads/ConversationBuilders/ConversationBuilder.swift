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
import ChatModels

struct ConversationBuilder: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    @State private var showNextPage = false

    var body: some View {
        NavigationStack {
            List {
                if viewModel.searchedContacts.count > 0 {
                    StickyHeaderSection(header: "Contacts.searched")
                        .listRowInsets(.zero)
                        .listRowSeparator(.hidden)
                    ForEach(viewModel.searchedContacts) { contact in
                        BuilderContactRowContainer(contact: contact, isSearchRow: true)
                    }
                    .padding()
                    .listRowInsets(.zero)
                }

                StickyHeaderSection(header: "Contacts.selectContacts")
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
                ForEach(viewModel.contacts) { contact in
                    BuilderContactRowContainer(contact: contact, isSearchRow: false)
                        .onAppear {
                            if viewModel.contacts.last == contact {
                                viewModel.loadMore()
                            }
                        }
                }
                .onDelete(perform: viewModel.delete)
                .padding()
                .listRowInsets(.zero)
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    TextField("General.searchHere", text: $viewModel.searchContactString)
                        .frame(height: 48)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    SelectedContactsView()
                        .padding(.horizontal, 8)
                        .frame(height: 48)
                }
                .background(.ultraThinMaterial)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                NavigationLink {
                    EditCreatedConversationDetail()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    SubmitBottomLabel(text: "General.next",
                                       enableButton: .constant(enabeleButton),
                                       isLoading: $viewModel.isCreateLoading)
                }
            }
        }
        .environment(\.defaultMinListRowHeight, 24)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isCreateLoading)
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isCreateLoading)
        }
        .onAppear {
            /// We use BuilderContactRowContainer view because it is essential to force the ineer contactRow View to show radio buttons.
            viewModel.isInSelectionMode = true
        }
        .onDisappear {
            viewModel.isInSelectionMode = false
        }
    }

    private var enabeleButton: Bool {
        viewModel.selectedContacts.count > 1 && !viewModel.isLoading
    }
}

struct SelectedContactsView: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel

    var body: some View {
        if viewModel.selectedContacts.count > 0 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.selectedContacts) { contact in
                        SelectedContact(viewModel: viewModel, contact: contact)
                    }
                }
            }
        }
    }
}

/// Step two to edit title and picture of the group/channel....
struct EditCreatedConversationDetail: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    @State var showImagePicker = false

    var body: some View {
        List {
            HStack {
                imagePickerButton
                TextField(viewModel.createConversationType == .normal ? "ConversationBuilder.enterGroupName" : "ConversationBuilder.enterChannelName" , text: $viewModel.conversationTitle)
                    .textContentType(.name)
                    .padding()
                    .font(.iransansBody)
                    .applyAppTextfieldStyle(innerBGColor: Color.clear, error: viewModel.showTitleError ? "ConversationBuilder.atLeatsEnterTwoCharacter" : nil)
            }
            .frame(height: 88)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparator(.hidden)
            
            StickyHeaderSection(header: "", height: 10)
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)

            let type = viewModel.createConversationType
            let isChannel = type == .channel || type == .publicChannel
            let typeName = String(localized: .init(isChannel ? "Thread.channel" : "Thread.group"))
            let localizedPublic = String(localized: .init("Thread.public"))

            Toggle(isOn: $viewModel.isPublic) {
                Text(String(format: localizedPublic, typeName))
            }
            .toggleStyle(MyToggleStyle())
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparator(.hidden)

            Section {
                ForEach(viewModel.selectedContacts) { contact in
                    ContactRow(isInSelectionMode: .constant(false), contact: contact)
                        .listRowBackground(Color.App.bgPrimary)
                        .listRowSeparatorTint(Color.App.dividerPrimary)
                }
                .onDelete(perform: viewModel.delete)
                .padding()
            } header: {
                StickyHeaderSection(header: "Thread.Tabs.members")
            }
            .listRowInsets(.zero)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .background(Color.App.bgPrimary)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: isLoading)
        .animation(.easeInOut, value: viewModel.conversationTitle)
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: viewModel.createConversationType == .normal ? "Contacts.createGroup" : "Contacts.createChannel",
                               enableButton: .constant(!isLoading),
                               isLoading: .constant(isLoading))
            {
                viewModel.createGroup()
            }
        }
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                viewModel.image = image
                viewModel.assetResources = assestResources ?? []
                viewModel.animateObjectWillChange()
                showImagePicker = false
                viewModel.startUploadingImage()
            }
        }
    }

    private var isLoading: Bool {
        viewModel.isCreateLoading || viewModel.isUploading
    }

    var imagePickerButton: some View {
        Button {
            showImagePicker.toggle()
        } label: {
            imagePickerButtonView
        }
    }

    private var imagePickerButtonView: some View {
        ZStack {
            Rectangle()
                .fill(Color("bg_icon"))
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .overlay(alignment: .center) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.App.textSecondary)
                }

            /// Showing the image taht user has selected.
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius:(28)))
                    .overlay(alignment: .center) {
                        if let percent = viewModel.uploadProfileProgress {
                            RoundedRectangle(cornerRadius: 28)
                                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .foregroundColor(Color.App.accent)
                                .rotationEffect(Angle(degrees: 270))
                                .frame(width: 61, height: 61)
                        }
                    }
            }
        }
        .background(Color.App.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius:(24)))
    }
}

struct BuilderContactRowContainer: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    let contact: Contact
    let isSearchRow: Bool
    var separatorColor: Color {
        if !isSearchRow {
            return viewModel.contacts.last == contact ? Color.clear : Color.App.dividerPrimary
        } else {
            return viewModel.searchedContacts.last == contact ? Color.clear : Color.App.dividerPrimary
        }
    }

    var body: some View {
        ‌BuilderContactRow(isInSelectionMode: $viewModel.isInSelectionMode, contact: contact)
            .id("\(isSearchRow ? "SearchRow" : "Normal")\(contact.id ?? 0)\(contact.blocked == true ? "Blocked" : "UnBlocked")")
            .animation(.spring(), value: viewModel.isInSelectionMode)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(separatorColor)
            .onAppear {
                if viewModel.contacts.last == contact {
                    viewModel.loadMore()
                }
            }
            .onTapGesture {
                if viewModel.isInSelectionMode {
                    viewModel.toggleSelectedContact(contact: contact)
                } else {
                    viewModel.closeBuilder()
                    AppState.shared.openThread(contact: contact)
                }
            }
    }
}

struct ‌BuilderContactRow: View {
    @Binding public var isInSelectionMode: Bool
    let contact: Contact
    var contactImageURL: String? { contact.image ?? contact.user?.image }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                let config = ImageLoaderConfig(url: contact.image ?? contact.user?.image ?? "", userName: contact.firstName)
                ImageLoaderView(imageLoader: .init(config: config))
                    .id("\(contact.image ?? "")\(contact.id ?? 0)")
                    .font(.iransansBody)
                    .foregroundColor(Color.App.textPrimary)
                    .frame(width: 52, height: 52)
                    .background(Color.App.color1.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius:(22)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
                        .padding(.leading, 16)
                        .lineLimit(1)
                        .font(.iransansBoldBody)
                        .foregroundColor(Color.App.textPrimary)
                    if let notSeenDuration = contact.notSeenDuration?.localFormattedTime {
                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"))
                        let time = String(format: lastVisitedLabel, notSeenDuration)
                        Text(time)
                            .padding(.leading, 16)
                            .font(.iransansBody)
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
                Spacer()
                if contact.blocked == true {
                    Text("General.blocked")
                        .font(.iransansCaption2)
                        .foregroundColor(Color.App.red)
                        .padding(.trailing, 4)
                }
                BuilderContactRowRadioButton(contact: contact)
            }
        }
        .contentShape(Rectangle())
        .animation(.easeInOut, value: contact.blocked)
        .animation(.easeInOut, value: contact)
    }

    var isOnline: Bool {
        contact.notSeenDuration ?? 16000 < 15000
    }
}


struct BuilderContactRowRadioButton: View {
    let contact: Contact
    @EnvironmentObject var viewModel: ConversationBuilderViewModel

    var body: some View {
        let isSelected = viewModel.isSelected(contact: contact)
        RadioButton(visible: $viewModel.isInSelectionMode, isSelected: .constant(isSelected)) { isSelected in
            viewModel.toggleSelectedContact(contact: contact)
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
