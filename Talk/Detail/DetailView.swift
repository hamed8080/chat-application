//
//  DetailView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatModels
import Photos
import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions

struct DetailView: View {
    @EnvironmentObject var viewModel: DetailViewModel
    @EnvironmentObject var contactsVM: ContactsViewModel
    @EnvironmentObject var navigationViewModel: NavigationModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                InfoView()
                BioDescription()
                UserName()
                CellPhoneNumber()
                StickyHeaderSection(header: "", height: 10)
                DetailTopButtons()
                    .padding([.top, .bottom])
                TabDetail(viewModel: viewModel)
            }
        }
        .background(Color.App.bgPrimary)
        .environmentObject(viewModel)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("General.info")
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.showAddToContactSheet) {
            if let user = viewModel.user {
                let editContact = Contact(firstName: user.firstName ?? "",
                                          lastName: user.lastName ?? "",
                                          user: .init(username: user.username ?? ""))
                let contactsVM = ContactsViewModel()
                AddOrEditContactView()
                    .environmentObject(contactsVM)
                    .onAppear {
                        contactsVM.editContact = editContact
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {                
                if viewModel.canShowEditButton {
                    Button {
                        viewModel.showEditContactOrEditGroup(contactsVM: contactsVM)
                    } label: {
                        Image(systemName: "pencil")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .padding(8)
                            .foregroundStyle(Color.App.primary)
                            .fontWeight(.heavy)
                    }
                }
            }

            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: DetailViewModel.self)
                }
            }
        }
        .animation(.easeInOut, value: viewModel.thread?.isPrivate == true)
        .animation(.interactiveSpring(), value: viewModel.isInEditMode)
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: Binding(get: { viewModel.participantViewModel?.isLoading ?? false },
                                               set: { newValue in viewModel.participantViewModel?.isLoading = newValue }))
        }
        .sheet(isPresented: $viewModel.showEditGroup) {
            EditGroup()
        }
        .sheet(isPresented: $viewModel.showContactEditSheet) {
            AddOrEditContactView()
        }
        .onReceive(viewModel.$dismiss) { newValue in
            if newValue {
                navigationViewModel.remove(type: DetailViewModel.self)
                dismiss()
            }
        }
    }
}

struct InfoView: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @StateObject private var fullScreenImageLoader: ImageLoaderViewModel = .init()

    var body: some View {
        VStack(spacing: 12) {
            let image = viewModel.url
            let avatarVM = AppState.shared.navViewModel?.threadsViewModel?.avatars(for: image ?? "") ?? .init()
            ImageLaoderView(imageLoader: avatarVM, url: viewModel.url, metaData: viewModel.thread?.metadata, userName: viewModel.title)
                .id("\(viewModel.url ?? "")\(viewModel.thread?.id ?? 0)")
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.App.blue.opacity(0.4))
                .cornerRadius(28)
                .onTapGesture {
                    fullScreenImageLoader.fetch(url: viewModel.url, metaData: viewModel.thread?.metadata, userName: viewModel.title, size: .ACTUAL, forceToDownloadFromServer: true)
                }
                .onReceive(fullScreenImageLoader.$image) { newValue in
                    if newValue.size.width > 0 {
                        appOverlayVM.galleryImageView = newValue
                    }
                }

            VStack(spacing: 8) {
                Text(viewModel.title)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.text)

                let count = viewModel.thread?.participantCount
                if viewModel.thread?.group == true, let count {
                    let label = String(localized: .init("Participant"))
                    Text("\(label) \(count)")
                        .font(.iransansCaption3)
                        .foregroundStyle(Color.App.hint)
                }

                if let bio = viewModel.bio {
                    Text(bio)
                        .font(.iransansCaption)
                        .foregroundColor(.gray)
                }

                if let notSeenString = viewModel.notSeenString {
                    Text(notSeenString)
                        .font(.iransansCaption3)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, idealHeight: 178, maxHeight: .infinity)
        .padding([.leading, .trailing, .top])
        .background(Color.App.divider)
    }
}

struct BioDescription: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        if let description = viewModel.thread?.description.validateString {
            InfoRowItem(key: "General.description", value: description)
        }
    }
}

struct UserName: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        if let participantName = viewModel.user?.name.validateString {
            InfoRowItem(key: "Settings.userName", value: participantName)
        }
    }
}

struct CellPhoneNumber: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        if let cellPhoneNumber = viewModel.cellPhoneNumber.validateString {
            InfoRowItem(key: "Participant.Search.Type.cellphoneNumber", value: cellPhoneNumber)
        }
    }
}

struct InfoRowItem: View {
    let key: String
    let value: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(value)
                    .font(.iransansSubtitle)
                    .foregroundStyle(Color.App.text)
                Text(String(localized: .init(key)))
                    .font(.iransansCaption)
                    .foregroundStyle(Color.App.hint)
            }
            Spacer()
        }
        .padding()
    }
}

struct DetailTopButtons: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        HStack(spacing: 16) {
            if viewModel.thread == nil {
                DetailViewButton(accessibilityText: "", icon: "message.fill") {
                    viewModel.createThread()
                }
            }

            DetailViewButton(accessibilityText: "", icon: viewModel.thread?.mute ?? false ? "bell.slash.fill" : "bell.fill") {
                viewModel.toggleMute()
            }
//
//            if viewModel.thread?.admin == true {
//                DetailViewButton(accessibilityText: "", icon: viewModel.thread?.isPrivate == true ? "lock.fill" : "globe") {
//                    viewModel.toggleThreadVisibility()
//                }
//            }

            DetailViewButton(accessibilityText: "", icon: "magnifyingglass") {

            }

            DetailViewButton(accessibilityText: "", icon: "phone.and.waveform.fill") {

            }
            .disabled(true)
            .opacity(0.4)
            .allowsHitTesting(false)

            DetailViewButton(accessibilityText: "", icon: "video.fill") {

            }
            .disabled(true)
            .opacity(0.4)
            .allowsHitTesting(false)

            Menu {
                if let conversation = viewModel.thread {
                    ThreadRowActionMenu(thread: conversation)
                } else if let user = viewModel.user {
                    UserActionMenu(participant: user)
                }
            } label: {
                DetailViewButton(accessibilityText: "", icon: "ellipsis"){}
            }
        }
        .padding([.leading, .trailing])
        .buttonStyle(.plain)
    }
}

struct TabDetail: View {
    let viewModel: DetailViewModel
    /// Select the participants tab if the conversation is a group. If not select index 1 which is mutual groups as the primary tab.
    var selectedIndex: Int { viewModel.thread?.group == true ? 0 : 1 }

    var body: some View {
        if let thread = viewModel.thread, let participantViewModel = viewModel.participantViewModel {
            VStack(spacing: 0) {
                TabViewsContainer(thread: thread, selectedTabIndex: selectedIndex)
                    .environmentObject(participantViewModel)
            }
        }
    }
}

struct DetailViewButton: View {
    let accessibilityText: String
    let icon: String
    let action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .transition(.asymmetric(insertion: .scale.animation(.easeInOut(duration: 2)), removal: .scale.animation(.easeInOut(duration: 2))))
                .accessibilityHint(accessibilityText)
                .foregroundColor(Color.App.primary)
        }
        .frame(width: 48, height: 48)
        .background(.ultraThickMaterial)
        .cornerRadius(8)
    }
}

struct SectionItem: View {
    let title: String
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label(String(localized: .init(title)), systemImage: systemName)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36, alignment: .leading)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding([.top, .bottom], 2)
        .buttonStyle(.bordered)
        .cornerRadius(12)
    }
}

struct DetailView_Previews: PreviewProvider {
    static var contact: Contact {
        let contact = MockData.contact
        contact.image = "https://imgv3.fotor.com/images/gallery/Realistic-Male-Profile-Picture.jpg"
        contact.user = User(cellphoneNumber: "+1 234 53 12",
                            profile: .init(bio: "I wish the best for you.", metadata: nil))
        AppState.shared.navViewModel = NavigationModel()
        AppState.shared.navViewModel?.threadsViewModel = .init()
        return contact
    }

    static var previews: some View {
        NavigationSplitView {} content: {} detail: {
            DetailView()
                .environmentObject(DetailViewModel(thread: MockData.thread, contact: contact, user: nil))
        }
        .previewDisplayName("Detail With Thread in Ipad")

        DetailView()
            .environmentObject(DetailViewModel(thread: MockData.thread, contact: contact, user: nil))
            .previewDisplayName("Detail With Thread in iPhone")

        DetailView()
            .environmentObject(DetailViewModel(thread: nil, contact: contact, user: nil))
            .previewDisplayName("Detail With Contant")
    }
}
