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
import TalkUI

struct ThreadDetailView: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) var dismiss


    var body: some View {
        ZStack {
            if let thread = viewModel.thread, #available(iOS 17.0, *) {
                VStack(spacing: 0) {
                    ThreadInfoView(viewModel: viewModel)
                    if let participantViewModel = viewModel.participantDetailViewModel {
                        UserName()
                            .environmentObject(participantViewModel)
                        CellPhoneNumber()
                            .environmentObject(participantViewModel)
                    }
                    PublicLink()
                    ThreadDescription()
                    ThreadDetailTopButtons()
                        .padding([.top, .bottom])
                    StickyHeaderSection(header: "", height: 10)
                    DetailTabs(thread: thread)
                        .environmentObject(viewModel.threadVM?.participantsViewModel ?? .init())
                }
            } else {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ThreadInfoView(viewModel: viewModel)
                        if let participantViewModel = viewModel.participantDetailViewModel {
                            UserName()
                                .environmentObject(participantViewModel)
                            CellPhoneNumber()
                                .environmentObject(participantViewModel)
                        }
                        PublicLink()
                        ThreadDescription()
                        ThreadDetailTopButtons()
                            .padding([.top, .bottom])
                        StickyHeaderSection(header: "", height: 10)
                        TabDetail(viewModel: viewModel)
                    }
                }
            }
        }
        .background(Color.App.bgPrimary)
        .environmentObject(viewModel)
        .navigationBarBackButtonHidden(true)
        .onReceive(viewModel.$dismiss) { newValue in
            if newValue {
                AppState.shared.objectsContainer.navVM.remove(type: ThreadDetailViewModel.self)
                AppState.shared.objectsContainer.threadDetailVM.clear()
                dismiss()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            toolbarView
        }
    }

    private var toolbarView: some View {
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

    var leadingViews: some View {
        NavigationBackButton {
            viewModel.threadVM?.scrollVM.disableExcessiveLoading()
            AppState.shared.objectsContainer.contactsVM.editContact = nil
            AppState.shared.objectsContainer.navVM.remove(type: ThreadDetailViewModel.self)
            AppState.shared.objectsContainer.threadDetailVM.clear()
        }
    }
}

class DetailTabViewModel: ObservableObject {
    let thread: Conversation
    @Published var selectedTab: Int = 0 {
        didSet {
            print("new value \(selectedTab)")
        }
    }

    var index: Int {
        let realIndex = max(0, hideMemberTab ? selectedTab - 1 : selectedTab)
        return realIndex
    }

    init(thread: Conversation) {
        self.thread = thread
    }

    var hideMemberTab: Bool {
        if thread.group == false || thread.group == nil {
            return true
        }
        if thread.group == true, thread.type?.isChannelType == true, (thread.admin == false || thread.admin == nil) {
            return true
        }
        return false
    }

    var tabs: [Tab] {
        let emptyView = AnyView(EmptyView())
        var tabs: [Tab] = [
            .init(title: "Thread.Tabs.members", view: emptyView),
            //            .init(title: "Thread.Tabs.mutualgroup", view: emptyView),
            .init(title: "Thread.Tabs.photos", view: emptyView),
            .init(title: "Thread.Tabs.videos", view: emptyView),
            .init(title: "Thread.Tabs.file", view: emptyView),
            .init(title: "Thread.Tabs.music", view: emptyView),
            .init(title: "Thread.Tabs.voice", view: emptyView),
            .init(title: "Thread.Tabs.link", view: emptyView)
        ]

        if hideMemberTab {
            tabs.removeAll(where: {$0.title == "Thread.Tabs.members"})
        }

        return tabs
    }
}

struct DetailTabs: View {
    @StateObject private var viewModel: DetailTabViewModel

    init(thread: Conversation) {
        self._viewModel = StateObject(wrappedValue: .init(thread: thread))
    }

    var body: some View {
        DetailTabsHeader(selectedTabIndex: .constant(viewModel.index), tabs: viewModel.tabs) { tappedIndex in
            viewModel.selectedTab = tappedIndex
        }
        TabView(selection: $viewModel.selectedTab) {
            if !viewModel.hideMemberTab {
                ScrollView(.vertical) {
                    MemberView()
                }
                .tag(0)
            }

            ScrollView(.vertical) {
                PictureView(conversation: viewModel.thread, messageType: .podSpacePicture)
            }
            .tag(1)

            ScrollView(.vertical) {
                VideoView(conversation: viewModel.thread, messageType: .podSpaceVideo)
            }
            .tag(2)

            ScrollView(.vertical) {
                FileView(conversation: viewModel.thread, messageType: .podSpaceFile)
            }
            .tag(3)

            ScrollView(.vertical) {
                MusicView(conversation: viewModel.thread, messageType: .podSpaceSound)
            }
            .tag(4)

            ScrollView(.vertical) {
                VoiceView(conversation: viewModel.thread, messageType: .podSpaceVoice)
            }
            .tag(5)

            ScrollView(.vertical) {
                LinkView(conversation: viewModel.thread, messageType: .link)
            }
            .tag(6)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

struct DetailTabsHeader: View {
    let selectedTabAction: (Int) -> Void
    @Binding var selectedTabIndex: Int
    let tabs: [Tab]
    @Namespace var id

    public init(selectedTabIndex: Binding<Int>, tabs: [Tab], selectedTabAction: @escaping (Int) -> Void ) {
        self._selectedTabIndex = selectedTabIndex
        self.tabs = tabs
        self.selectedTabAction = selectedTabAction
    }

    var body: some View {

        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                HStack(spacing: 28) {
                    ForEach(tabs) { tab in
                        let index = tabs.firstIndex(where: { $0.title == tab.title })
                        Button {
                            selectedTabAction(index ?? 0)
                            selectedTabIndex = index ?? 0
                        } label: {
                            VStack(spacing: 6) {
                                HStack(spacing: 8) {
                                    if let icon = tab.icon {
                                        Image(systemName: icon)
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(Color.App.textSecondary)
                                            .fixedSize()
                                    }
                                    Text(String(localized: .init(tab.title)))
                                        .font(index == selectedTabIndex ? .iransansBoldCaption : .iransansCaption)
                                        .fixedSize()
                                        .foregroundStyle(index == selectedTabIndex ? Color.App.textPrimary : Color.App.textSecondary)
                                }
                                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))

                                if index == selectedTabIndex {
                                    Rectangle()
                                        .fill(Color.App.accent)
                                        .frame(height: 3)
                                        .cornerRadius(2, corners: [.topLeft, .topRight])
                                        .matchedGeometryEffect(id: "DetailTabSeparator", in: id)
                                }
                            }
                            .frame(height: 48)
                            .contentShape(Rectangle())
                            .fixedSize(horizontal: true, vertical: true)
                        }
                        .buttonStyle(.plain)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                    }
                }
                .animation(.spring(), value: selectedTabIndex)
                .padding([.leading, .trailing])
                Spacer()
            }
        }
    }
}

struct TarilingEditConversation: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if viewModel.canShowEditConversationButton == true {
            NavigationLink {
                if viewModel.canShowEditConversationButton, let viewModel = viewModel.editConversationViewModel {
                    EditGroup()
                        .environmentObject(viewModel)
                        .navigationBarBackButtonHidden(true)
                }
            } label: {
                Image(systemName: "pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(8)
                    .foregroundStyle(colorScheme == .dark ? Color.App.accent : Color.App.white)
                    .fontWeight(.heavy)
            }
        } else if let viewModel = viewModel.participantDetailViewModel {
            EditContactTrailingButton()
                .environmentObject(viewModel)
        }
    }
}

struct EditContactTrailingButton: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if viewModel.partnerContact != nil {
            NavigationLink {
                EditContactInParticipantDetailView()
                    .environmentObject(viewModel)
                    .background(Color.App.bgSecondary)
                    .navigationBarBackButtonHidden(true)
            } label: {
                Image(systemName: "pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(8)
                    .foregroundStyle(colorScheme == .dark ?  Color.App.accent : Color.App.white)
                    .fontWeight(.heavy)
            }
        }
    }
}

struct EditContactInParticipantDetailView: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel
    @State var contactValue: String = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @Environment(\.dismiss) var dismiss
    var editContact: Contact? { viewModel.partnerContact }
    @FocusState var focusState: ContactFocusFileds?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("General.firstName", text: $firstName)
                    .focused($focusState, equals: .firstName)
                    .textContentType(.name)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "General.firstName", isFocused: focusState == .firstName) {
                        focusState = .firstName
                    }
                TextField(optioanlAPpend(text: "General.lastName"), text: $lastName)
                    .focused($focusState, equals: .lastName)
                    .textContentType(.familyName)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "General.lastName", isFocused: focusState == .lastName) {
                        focusState = .lastName
                    }
                TextField("Contacts.Add.phoneOrUserName", text: $contactValue)
                    .focused($focusState, equals: .contactValue)
                    .keyboardType(.default)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "Contacts.Add.phoneOrUserName", error: nil, isFocused: focusState == .contactValue) {
                        focusState = .contactValue
                    }
                    .disabled(true)
                    .opacity(0.3)
                if !isLargeSize {
                    Spacer()
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            toolbarView
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            let title = "Contacts.Edit.title"
            SubmitBottomButton(text: title, enableButton: .constant(enableButton), isLoading: $viewModel.isLoading) {
                submit()
            }
        }
        .animation(.easeInOut, value: enableButton)
        .animation(.easeInOut, value: focusState)
        .font(.iransansBody)
        .onChange(of: viewModel.successEdited) { newValue in
            if newValue == true {
                withAnimation {
                    dismiss()
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            firstName = editContact?.firstName ?? ""
            lastName = editContact?.lastName ?? ""
            contactValue = editContact?.computedUserIdentifire ?? ""
            focusState = .firstName
            viewModel.successEdited = false
        }
    }

    private var isLargeSize: Bool {
        let mode = UIApplication.shared.windowMode()
        if mode == .ipadFullScreen || mode == .ipadHalfSplitView || mode == .ipadTwoThirdSplitView {
            return true
        } else {
            return false
        }
    }

    private var enableButton: Bool {
        !firstName.isEmpty && !contactValue.isEmpty && !viewModel.isLoading
    }

    func submit() {
        /// Add or edit use same method.
        viewModel.editContact(contactValue: contactValue, firstName: firstName, lastName: lastName)
    }

    func optioanlAPpend(text: String) -> String {
        "\(String(localized: .init(text))) \(String(localized: "General.optional"))"
    }

    var toolbarView: some View {
        VStack(spacing: 0) {
            ToolbarView(title: "Contacts.Edit.title",
                        showSearchButton: false,
                        leadingViews: leadingViews,
                        centerViews: EmptyView(),
                        trailingViews: EmptyView()) {_ in }
        }
    }

    var leadingViews: some View {
        NavigationBackButton {
            
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
                                       userName: String.splitedCharacter(viewModel.thread?.title ?? ""),
                                       forceToDownloadFromServer: true)
        self._fullScreenImageLoader = .init(wrappedValue: .init(config: config))
    }

    var body: some View {
        HStack(spacing: 16) {
            let image = viewModel.thread?.computedImageURL ?? viewModel.participantDetailViewModel?.participant.image ?? ""
            let avatarVM = AppState.shared.objectsContainer.threadsVM.avatars(for: image,
                                                                              metaData: viewModel.thread?.metadata,
                                                                              userName: String.splitedCharacter(viewModel.thread?.title ?? ""))
            let config = ImageLoaderConfig(url: image,
                                           metaData: viewModel.thread?.metadata,
                                           userName: String.splitedCharacter(viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name ?? ""))
            let defaultLoader = ImageLoaderViewModel(config: config)
            ImageLoaderView(imageLoader: avatarVM)
                .id("\(image)\(viewModel.thread?.id ?? 0)")
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(String.getMaterialColorByCharCode(str: viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name ?? ""))
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .overlay {
                    if viewModel.thread?.type == .selfThread {
                        SelfThreadImageView(imageSize: 64, iconSize: 28)
                    }
                }
                .onTapGesture {
                    Task {
                        await fullScreenImageLoader.fetch()
                    }
                }
                .onReceive(fullScreenImageLoader.$image) { newValue in
                    if newValue.size.width > 0 {
                        appOverlayVM.galleryImageView = newValue
                    }
                }
                .onReceive(NotificationCenter.thread.publisher(for: .thread)) { notification in
                    if let threadEvent = notification.object as? ThreadEventTypes, case .updatedInfo(_) = threadEvent {
                        Task {
                            await defaultLoader.fetch()
                        }
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                let threadName = viewModel.participantDetailViewModel?.participant.contactName ?? viewModel.thread?.computedTitle ?? ""
                Text(threadName)
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
            InfoRowItem(key: "General.description", value: description, lineLimit: nil)
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
                InfoRowItem(key: "Thread.inviteLink", value: shortJoinLink, lineLimit: 1, button: AnyView(EmptyView()))
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
    let lineLimit: Int?

    init(key: String, value: String, lineLimit: Int? = 2, button: AnyView? = nil) {
        self.key = key
        self.value = value
        self.button = button
        self.lineLimit = lineLimit
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(String(localized: .init(key)))
                    .font(.iransansCaption)
                    .foregroundStyle(Color.App.textSecondary)
                Text(value)
                    .font(.iransansSubtitle)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
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
        let thread = viewModel.thread ?? .init(id: LocalId.emptyThread.rawValue)
        let participantViewModel = viewModel.threadVM?.participantsViewModel ?? .init()
        ConversationDetailTabViews(thread: thread)
            .environmentObject(participantViewModel)
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
        return contact
    }

    static var previews: some View {
        NavigationSplitView {} content: {} detail: {
            ThreadDetailView()
                .environmentObject(ThreadDetailViewModel())
        }
        .previewDisplayName("Detail With Thread in Ipad")

        ThreadDetailView()
            .environmentObject(ThreadDetailViewModel())
            .previewDisplayName("Detail With Thread in iPhone")
    }
}
