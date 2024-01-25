//
//  ParticipantDetailView.swift
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

struct ParticipantDetailView: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                ParticipantInfoView(viewModel: viewModel)
                UserName()
                CellPhoneNumber()
                StickyHeaderSection(header: "", height: 10)
                ParticipantDetailTopButtons()
                    .padding([.top, .bottom])
                StickyHeaderSection(header: "", height: 10)
                StickyHeaderSection(header: "", height: 10)
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
                AppState.shared.objectsContainer.navVM.remove(type: ParticipantDetailViewModel.self)
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
                            trailingViews: trailingViews) { _ in }
            }
        }
    }

    @ViewBuilder var trailingViews: some View {
        if viewModel.canShowEditButton {
            NavigationLink {
                let participant = viewModel.participant
                let editContact = Contact(firstName: participant.firstName ?? "",
                                          lastName: participant.lastName ?? "",
                                          user: .init(username: participant.username ?? ""))
                let contactsVM = ContactsViewModel()
                AddOrEditContactView()
                    .environmentObject(contactsVM)
                    .onAppear {
                        contactsVM.editContact = editContact
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

    var leadingViews: some View {
        NavigationBackButton {
            dismiss()
        }
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

struct ParticipantDetailTopButtons: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel
    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            DetailViewButton(accessibilityText: "", icon: "message.fill") {
                viewModel.createThread()
            }
            //
            //            if viewModel.thread?.admin == true {
            //                DetailViewButton(accessibilityText: "", icon: viewModel.thread?.isPrivate == true ? "lock.fill" : "globe") {
            //                    viewModel.toggleThreadVisibility()
            //                }
            //            }

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
                    UserActionMenu(showPopover: $showPopover, participant: viewModel.participant)
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

struct ParticipantInfoView: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @EnvironmentObject var viewModel: ParticipantDetailViewModel
    @StateObject private var fullScreenImageLoader: ImageLoaderViewModel

    init(viewModel: ParticipantDetailViewModel) {
        let config = ImageLoaderConfig(url: viewModel.url ?? "",
                                       size: .ACTUAL,
                                       userName: viewModel.title,
                                       forceToDownloadFromServer: true)
        self._fullScreenImageLoader = .init(wrappedValue: .init(config: config))
    }

    var body: some View {
        HStack(spacing: 16) {
            let image = viewModel.participant.image ?? ""
            let avatarVM = AppState.shared.navViewModel?.threadsViewModel?.avatars(for: image, metaData: nil, userName: nil)
            let config = ImageLoaderConfig(url: image, userName: viewModel.participant.name ?? "")
            let defaultLoader = ImageLoaderViewModel(config: config)
            ImageLoaderView(imageLoader: avatarVM ?? defaultLoader)
                .id("\(viewModel.url ?? "")")
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
                Text(viewModel.title)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.textPrimary)

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
