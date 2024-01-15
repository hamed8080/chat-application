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
import Additive
import TalkModels

struct DetailView: View {
    @EnvironmentObject var viewModel: DetailViewModel
    @EnvironmentObject var contactsVM: ContactsViewModel
    @EnvironmentObject var navigationViewModel: NavigationModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                InfoView(viewModel: viewModel)
                UserName()
                CellPhoneNumber()
                PublicLink()
                BioDescription()
                StickyHeaderSection(header: "", height: 10)
                DetailTopButtons()
                    .padding([.top, .bottom])
                StickyHeaderSection(header: "", height: 10)              
                StickyHeaderSection(header: "", height: 10)
                TabDetail(viewModel: viewModel)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .background(Color.App.bgPrimary)
        .environmentObject(viewModel)
        .navigationBarTitleDisplayMode(.inline)
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
        .animation(.easeInOut, value: viewModel.thread?.type?.isPrivate == true)
        .animation(.interactiveSpring(), value: viewModel.isInEditMode)
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
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                ToolbarView(searchId: "DetailView",
                            title: "General.info",
                            showSearchButton: false,
                            searchPlaceholder: "General.searchHere",
                            searchKeyboardType: .default,
                            leadingViews: leadingViews,
                            centerViews: EmptyView(),
                            trailingViews: trailingViews) { searchValue in
                    viewModel.threadVM?.searchedMessagesViewModel.searchText = searchValue
                }
                if let viewModel = viewModel.threadVM {
                    ThreadSearchList(threadVM: viewModel)
                        .environmentObject(viewModel.searchedMessagesViewModel)
                }
            }
        }
    }

    @ViewBuilder var trailingViews: some View {
        if viewModel.canShowEditButton {
            Button {
                viewModel.showEditContactOrEditGroup(contactsVM: contactsVM)
            } label: {
                Image(systemName: "pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(8)
                    .foregroundStyle(Color.App.accent)
                    .fontWeight(.heavy)
            }
        }
    }

    var leadingViews: some View {
        NavigationBackButton {
            viewModel.threadVM?.scrollVM.disableExcessiveLoading()
            AppState.shared.navViewModel?.remove(type: DetailViewModel.self)
        }
    }
}

struct InfoView: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @StateObject private var fullScreenImageLoader: ImageLoaderViewModel

    init(viewModel: DetailViewModel) {
        let config = ImageLoaderConfig(url: viewModel.url ?? "",
                                       size: .ACTUAL,
                                       metaData: viewModel.thread?.metadata,
                                       userName: viewModel.title,
                                       forceToDownloadFromServer: true)
        self._fullScreenImageLoader = .init(wrappedValue: .init(config: config))
    }

    var body: some View {
        HStack(spacing: 16) {
            let image = viewModel.url
            let avatarVM = AppState.shared.navViewModel?.threadsViewModel?.avatars(for: image ?? "", metaData: nil, userName: nil)
            let config = ImageLoaderConfig(url: viewModel.url ?? "", metaData: viewModel.thread?.metadata, userName: viewModel.title)
            let defaultLoader = ImageLoaderViewModel(config: config)
            ImageLoaderView(imageLoader: avatarVM ?? defaultLoader)
                .id("\(viewModel.url ?? "")\(viewModel.thread?.id ?? 0)")
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.App.color1.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .onTapGesture {
                    fullScreenImageLoader.fetch()
                }
                .onReceive(fullScreenImageLoader.$image) { newValue in
                    if newValue.size.width > 0 {
                        appOverlayVM.galleryImageView = newValue
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .thread)) { notification in
                    if let threadEvent = notification.object as? ThreadEventTypes, case .updatedInfo(_) = threadEvent {
                        defaultLoader.fetch()
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.textPrimary)

                let count = viewModel.participantViewModel?.thread?.participantCount
                if viewModel.thread?.group == true, let countString = count?.localNumber(locale: Language.preferredLocale) {
                    let label = String(localized: .init("Participant"))
                    Text("\(label) \(countString)")
                        .font(.iransansCaption3)
                        .foregroundStyle(Color.App.textSecondary)
                }

                if let notSeenString = viewModel.notSeenString {
                    let localized = String(localized: .init("Contacts.lastVisited"))
                    let formatted = String(format: localized, notSeenString)
                    Text(formatted)
                        .font(.iransansCaption3)
                }
            }
            Spacer()
        }
        .frame(height: 56)
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.all, 16)
        .background(Color.App.dividerPrimary)
    }
}

struct BioDescription: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        if EnvironmentValues.isTalkTest {
            if let description = viewModel.partner?.chatProfileVO?.bio ?? viewModel.thread?.description.validateString {
                InfoRowItem(key: "General.description", value: description)
            }
        }
    }
}

struct PublicLink: View {
    @EnvironmentObject var viewModel: DetailViewModel
    private var shortJoinLink: String { "talk/\(viewModel.thread?.uniqueName ?? "")" }
    private var joinLink: String { "\(AppRoutes.joinLink)\(viewModel.thread?.uniqueName ?? "")" }

    var body: some View {
        if viewModel.thread?.uniqueName != nil {
            Button {
                UIPasteboard.general.string = joinLink
                let icon = Image(systemName: "doc.on.doc")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.App.textPrimary)
                AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.copied", messageColor: Color.App.textPrimary)
            } label: {
                InfoRowItem(key: "Thread.inviteLink", value: shortJoinLink, button: AnyView(EmptyView()))
            }
        }
    }

//    var qrButton: some View {
//        Button {
//            withAnimation {
//                UIPasteboard.general.string = joinLink
//            }
//        } label: {
//            Image(systemName: "qrcode")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 20, height: 20)
//                .padding()
//                .foregroundColor(Color.App.white)
//                .contentShape(Rectangle())
//        }
//        .frame(width: 40, height: 40)
//        .background(Color.App.textSecondary)
//        .clipShape(RoundedRectangle(cornerRadius:(20)))
//    }
}

struct UserName: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        if let participantName = viewModel.partner?.username ?? viewModel.user?.name.validateString {
            InfoRowItem(key: "Settings.userName", value: participantName)
        }
    }
}

struct CellPhoneNumber: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        if let cellPhoneNumber = viewModel.partnerContact?.cellphoneNumber ?? viewModel.cellPhoneNumber.validateString {
            InfoRowItem(key: "Participant.Search.Type.cellphoneNumber", value: cellPhoneNumber)
        }
    }
}

struct InfoRowItem: View {
    let key: String
    let value: String
    let button: AnyView?

    init(key: String, value: String, button: AnyView? = nil) {
        self.key = key
        self.value = value
        self.button = button
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(value)
                    .font(.iransansSubtitle)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Text(String(localized: .init(key)))
                    .font(.iransansCaption)
                    .foregroundStyle(Color.App.textSecondary)
            }
            Spacer()
            button
        }
        .padding()
    }
}

struct DetailTopButtons: View {
    @EnvironmentObject var viewModel: DetailViewModel
    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            if viewModel.thread == nil {
                DetailViewButton(accessibilityText: "", icon: "message.fill") {
                    viewModel.createThread()
                }
            }

            if viewModel.thread?.type != .selfThread {
                DetailViewButton(accessibilityText: "", icon: viewModel.thread?.mute ?? false ? "bell.slash.fill" : "bell.fill") {
                    viewModel.toggleMute()
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
            }
//
//            if viewModel.thread?.admin == true {
//                DetailViewButton(accessibilityText: "", icon: viewModel.thread?.isPrivate == true ? "lock.fill" : "globe") {
//                    viewModel.toggleThreadVisibility()
//                }
//            }

            if viewModel.threadVM?.threadId != nil {
                DetailViewButton(accessibilityText: "", icon: "magnifyingglass") {
                    NotificationCenter.default.post(name: .forceSearch, object: "DetailView")
                }
            }

//            Menu {
//                if let conversation = viewModel.thread {
//                    ThreadRowActionMenu(isDetailView: true, thread: conversation)
//                        .environmentObject(AppState.shared.objectsContainer.threadsVM)
//                }
//                if let user = viewModel.user {
//                    UserActionMenu(participant: user)
//                }
//            } label: {
//                DetailViewButton(accessibilityText: "", icon: "ellipsis"){}
//            }

            DetailViewButton(accessibilityText: "", icon: "ellipsis") {
                showPopover.toggle()
            }
            .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    if let conversation = viewModel.thread {
                        ThreadRowActionMenu(showPopover: $showPopover, isDetailView: true, thread: conversation)
                            .environmentObject(AppState.shared.objectsContainer.threadsVM)
                    }
                    if let user = viewModel.user {
                        UserActionMenu(participant: user)
                    }
                }
                .foregroundColor(.primary)
                .frame(width: 196)
                .background(MixMaterialBackground())
                .clipShape(RoundedRectangle(cornerRadius:((12))))
                .presentationCompactAdaptation(horizontal: .popover, vertical: .popover)
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        .buttonStyle(.plain)
    }
}

struct TabDetail: View {
    let viewModel: DetailViewModel

    var body: some View {
        if let thread = viewModel.thread, let participantViewModel = viewModel.participantViewModel {
            ConversationDetailTabViews(thread: thread)
                .environmentObject(participantViewModel)
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
                .foregroundColor(Color.App.accent)
                .contentShape(Rectangle())
        }
        .frame(width: 48, height: 48)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius:(8)))
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
        .clipShape(RoundedRectangle(cornerRadius:(12)))
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
