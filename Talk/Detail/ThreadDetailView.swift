//
//  DetailView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions
import Additive
import TalkModels

struct ThreadDetailView: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                ThreadInfoView(viewModel: viewModel)
                if let participantViewModel = viewModel.participantDetailViewModel {
                    UserName()
                        .environmentObject(participantViewModel)
                    CellPhoneNumber()
                        .environmentObject(participantViewModel)
                }
                PublicLink()
                ThreadDescription()
                StickyHeaderSection(header: "", height: 10)
                ThreadDetailTopButtons()
                    .padding([.top, .bottom])
                StickyHeaderSection(header: "", height: 10)              
                StickyHeaderSection(header: "", height: 10)
                if viewModel.thread?.id != nil, viewModel.thread?.id != LocalId.emptyThread.rawValue {
                    TabDetail(viewModel: viewModel)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .background(Color.App.bgPrimary)
        .environmentObject(viewModel)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .animation(.interactiveSpring(), value: viewModel.isInEditMode)
        .onReceive(viewModel.$dismiss) { newValue in
            if newValue {
                AppState.shared.objectsContainer.navVM.remove(type: ThreadDetailViewModel.self)
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
                            trailingViews: TarilingEditConversation()) { searchValue in
                    viewModel.threadVM?.searchedMessagesViewModel.searchText = searchValue
                }
                if let viewModel = viewModel.threadVM {
                    ThreadSearchList(threadVM: viewModel)
                        .environmentObject(viewModel.searchedMessagesViewModel)
                }
            }
        }
    }

    var leadingViews: some View {
        NavigationBackButton {
            viewModel.threadVM?.scrollVM.disableExcessiveLoading()
            AppState.shared.objectsContainer.contactsVM.editContact = nil
            AppState.shared.navViewModel?.remove(type: ThreadDetailViewModel.self)
        }
    }
}

struct TarilingEditConversation: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel

    var body: some View {
        if viewModel.participantDetailViewModel?.partnerContact != nil || viewModel.participantDetailViewModel?.participant.contactId != nil || viewModel.canShowEditConversationButton == true {
            NavigationLink {
                if viewModel.canShowEditConversationButton, let viewModel = viewModel.editConversationViewModel {
                    EditGroup()
                        .environmentObject(viewModel)
                        .navigationBarBackButtonHidden(true)
                } else if let contactsVM = viewModel.participantDetailViewModel?.contactsVM {
                    AddOrEditContactView(showToolbar: true)
                        .environmentObject(contactsVM)
                        .background(Color.App.bgSecondary)
                        .navigationBarBackButtonHidden(true)
                        .onAppear {
                            contactsVM.isLoading = false
                        }
                }
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
}

struct ThreadInfoView: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @StateObject private var fullScreenImageLoader: ImageLoaderViewModel

    init(viewModel: ThreadDetailViewModel) {
        let config = ImageLoaderConfig(url: viewModel.thread?.computedImageURL ?? "",
                                       size: .ACTUAL,
                                       metaData: viewModel.thread?.metadata,
                                       userName: viewModel.thread?.title ?? "",
                                       forceToDownloadFromServer: true)
        self._fullScreenImageLoader = .init(wrappedValue: .init(config: config))
    }

    var body: some View {
        HStack(spacing: 16) {
            let image = viewModel.thread?.computedImageURL ?? viewModel.participantDetailViewModel?.participant.image ?? ""
            let avatarVM = AppState.shared.navViewModel?.threadsViewModel?.avatars(for: image,
                                                                                   metaData: viewModel.thread?.metadata,
                                                                                   userName: viewModel.thread?.title)
            let config = ImageLoaderConfig(url: image,
                                           metaData: viewModel.thread?.metadata,
                                           userName: viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name)
            let defaultLoader = ImageLoaderViewModel(config: config)
            ImageLoaderView(imageLoader: avatarVM ?? defaultLoader)
                .id("\(image)\(viewModel.thread?.id ?? 0)")
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
                .onReceive(NotificationCenter.thread.publisher(for: .thread)) { notification in
                    if let threadEvent = notification.object as? ThreadEventTypes, case .updatedInfo(_) = threadEvent {
                        defaultLoader.fetch()
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.thread?.title ?? "")
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.textPrimary)

                let count = viewModel.threadVM?.participantsViewModel.thread?.participantCount
                if viewModel.thread?.group == true, let countString = count?.localNumber(locale: Language.preferredLocale) {
                    let label = String(localized: .init("Participant"))
                    Text("\(label) \(countString)")
                        .font(.iransansCaption3)
                        .foregroundStyle(Color.App.textSecondary)
                }

                if let notSeenString = viewModel.participantDetailViewModel?.notSeenString {
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

struct ThreadDescription: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel

    var body: some View {
        if let description = viewModel.thread?.description.validateString {
            InfoRowItem(key: "General.description", value: description)
        }
    }
}

struct PublicLink: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
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

struct ThreadDetailTopButtons: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
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
                    NotificationCenter.forceSearch.post(name: .forceSearch, object: "DetailView")
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
                    if let thread = viewModel.thread {
                        ThreadRowActionMenu(showPopover: $showPopover, isDetailView: true, thread: thread)
                            .environmentObject(AppState.shared.objectsContainer.threadsVM)
                    }
                    if let participant = viewModel.participantDetailViewModel?.participant {
                        UserActionMenu(showPopover: $showPopover, participant: participant)
                    }
                }
                .foregroundColor(.primary)
                .frame(width: 246)
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
    let viewModel: ThreadDetailViewModel

    var body: some View {
        if let participantViewModel = viewModel.threadVM?.participantsViewModel, let thread = viewModel.thread {
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

struct UserName: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        if let participantName = viewModel.participant.username.validateString {
            InfoRowItem(key: "Settings.userName", value: participantName)
        }
    }
}

struct CellPhoneNumber: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        if let cellPhoneNumber = viewModel.cellPhoneNumber.validateString {
            InfoRowItem(key: "Participant.Search.Type.cellphoneNumber", value: cellPhoneNumber)
        }
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
            ThreadDetailView()
                .environmentObject(ThreadDetailViewModel(thread: MockData.thread))
        }
        .previewDisplayName("Detail With Thread in Ipad")

        ThreadDetailView()
            .environmentObject(ThreadDetailViewModel(thread: MockData.thread))
            .previewDisplayName("Detail With Thread in iPhone")
    }
}
