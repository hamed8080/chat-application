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
    @State private var showStickyToolbar = false
    @State private var selectedTabIndex = 0
    let tabs: [Tab]

    init(thread: Conversation?) {
        if let thread = thread {
            self.tabs = ThreadDetailView.makeTabs(thread: thread)
        } else {
            self.tabs = []
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    topView
                    CustomDetailTabView(tabs: tabs, tabButtons: { tabButtons } )
                        .environmentObject(viewModel.threadVM?.participantsViewModel ?? .init())
                        .selectedTabIndx(index: selectedTabIndex)
                }
            }
        }
        .animation(.easeInOut, value: showStickyToolbar)
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
//        .overlay(alignment: .top) {
//            if showStickyToolbar {
//                tabButtons
//                    .background(MixMaterialBackground(color: Color.App.bgToolbar))
//            }
//        }
        .safeAreaInset(edge: .top, spacing: 0) {
            toolbarView
        }
    }

    static func makeTabs(thread: Conversation) -> [Tab] {
        var tabs: [Tab] = [
            .init(title: "Thread.Tabs.members", view: AnyView(MemberView().ignoresSafeArea(.all))),
            //            .init(title: "Thread.Tabs.mutualgroup", view: AnyView(MutualThreadsView().ignoresSafeArea(.all))),
            .init(title: "Thread.Tabs.photos", view: AnyView(PictureView(conversation: thread, messageType: .podSpacePicture))),
            .init(title: "Thread.Tabs.videos", view: AnyView(VideoView(conversation: thread, messageType: .podSpaceVideo))),
            .init(title: "Thread.Tabs.music", view: AnyView(MusicView(conversation: thread, messageType: .podSpaceSound))),
            .init(title: "Thread.Tabs.voice", view: AnyView(VoiceView(conversation: thread, messageType: .podSpaceVoice))),
            .init(title: "Thread.Tabs.file", view: AnyView(FileView(conversation: thread, messageType: .podSpaceFile))),
            .init(title: "Thread.Tabs.link", view: AnyView(LinkView(conversation: thread, messageType: .link)))
        ]
        if thread.group == false || thread.group == nil {
            tabs.removeAll(where: {$0.title == "Thread.Tabs.members"})
        }
        if thread.group == true, thread.type?.isChannelType == true, (thread.admin == false || thread.admin == nil) {
            tabs.removeAll(where: {$0.title == "Thread.Tabs.members"})
        }
        //        if thread.group == true || thread.type == .selfThread || !EnvironmentValues.isTalkTest {
        //            tabs.removeAll(where: {$0.title == "Thread.Tabs.mutualgroup"})
        //        }
        //        self.tabs = tabs
        return tabs
    }

    private var tabButtons: TabViewButtonsContainer {
        TabViewButtonsContainer(selectedTabIndex: $selectedTabIndex, tabs: tabs)
    }

    @ViewBuilder
    private var topView: some View {
        VStack {
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
        }
        .onAppear {
            showStickyToolbar = false
        }
        .onDisappear {
            showStickyToolbar = true
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
            Task {
                await viewModel.threadVM?.scrollVM.disableExcessiveLoading()
                AppState.shared.objectsContainer.contactsVM.editContact = nil
                AppState.shared.objectsContainer.navVM.remove(type: ThreadDetailViewModel.self)
                AppState.shared.objectsContainer.threadDetailVM.clear()
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
                Image("ic_edit")
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
                Image("ic_edit")
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
        let description = viewModel.thread?.description.validateString ?? "General.noDescription".localized()
        InfoRowItem(key: "General.description", value: description, lineLimit: nil)
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
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            button
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
            ThreadDetailView(thread: .init())
                .environmentObject(ThreadDetailViewModel())
        }
        .previewDisplayName("Detail With Thread in Ipad")

        ThreadDetailView(thread: .init())
            .environmentObject(ThreadDetailViewModel())
            .previewDisplayName("Detail With Thread in iPhone")
    }
}
