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

struct DetailView: View {
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack {
                VStack(spacing: 12) {
                    InfoView()
                        .padding([.top], 16)
                    DetailTopButtons()
                        .padding([.bottom], 16)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(.ultraThickMaterial)
                .cornerRadius(12)
            }
            .padding([.leading, .trailing])
            TabDetail(viewModel: viewModel)
        }
        .environmentObject(viewModel)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("General.info")
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.showAddToContactSheet) {
            if let user = viewModel.user {
                let editContact = Contact(firstName: user.firstName ?? "",
                                          lastName: user.lastName ?? "",
                                          user: .init(username: user.username ?? ""))
                AddOrEditContactView(editContact: editContact, contactType: .userName)
            }
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                self.viewModel.image = image
                self.viewModel.assetResources = assestResources ?? []
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                VStack(alignment: .center) {
                    if viewModel.thread?.canEditInfo == true {
                        Button {
                            if viewModel.isInEditMode {
                                // submited
                                viewModel.updateThreadInfo()
                            }
                            viewModel.isInEditMode.toggle()
                        } label: {
                            Text(viewModel.isInEditMode ? "General.done" : "General.edit")
                                .font(.iransansBody)
                        }
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
        .onReceive(viewModel.$dismiss) { newValue in
            if newValue {
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
            if let image = viewModel.url, let avatarVM = AppState.shared.navViewModel?.threadViewModel?.avatars(for: image) {
                ImageLaoderView(imageLoader: avatarVM, url: viewModel.url, metaData: viewModel.thread?.metadata, userName: viewModel.title)
                    .id("\(viewModel.url ?? "")\(viewModel.thread?.id ?? 0)")
                    .font(.system(size: 16).weight(.heavy))
                    .foregroundColor(.white)
                    .frame(width: 128, height: 128)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(64)
                    .onTapGesture {
                        if viewModel.isInEditMode, viewModel.thread?.canEditInfo == true {
                            viewModel.showImagePicker = true
                        } else {
                            fullScreenImageLoader.fetch(url: viewModel.url, metaData: viewModel.thread?.metadata, userName: viewModel.title, size: .ACTUAL, forceToDownloadFromServer: true)
                        }
                    }
                    .onReceive(fullScreenImageLoader.$image) { newValue in
                        if newValue.size.width > 0 {
                            appOverlayVM.galleryImageView = newValue
                        }
                    }
            }

            VStack(spacing: 8) {
                if viewModel.thread?.canEditInfo == true {
                    TextField("General.title", text: $viewModel.editTitle)
                        .frame(minHeight: 36)
                        .textFieldStyle((!viewModel.isInEditMode) ? .clear : .customBorderedWith(minHeight: 36, cornerRadius: 12))
                        .font(.iransansBody)
                        .multilineTextAlignment(.center)
                        .disabled(!viewModel.isInEditMode)
                } else {
                    Text(viewModel.title)
                        .font(.iransansBoldTitle)
                }

                if viewModel.thread?.canEditInfo == true {
                    TextField("General.description", text: $viewModel.threadDescription)
                        .frame(minHeight: 36)
                        .textFieldStyle((!viewModel.isInEditMode) ? .clear : .customBorderedWith(minHeight: 36, cornerRadius: 12))
                        .font(.iransansCaption)
                        .multilineTextAlignment(.center)
                        .disabled(!viewModel.isInEditMode)
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
        .padding([.leading, .trailing])
    }
}

struct DetailTopButtons: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        HStack(spacing: 16) {
            if viewModel.thread == nil {
                Button {
                    viewModel.createThread()
                } label: {
                    ActionImage(systemName: "message.fill")
                }
            }

            Button {
                viewModel.toggleMute()
            } label: {
                ActionImage(systemName: viewModel.thread?.mute ?? false ? "bell.slash.fill" : "bell.fill")
                    .foregroundColor(viewModel.thread?.mute ?? false ? .red : .blue)
            }

            if viewModel.thread?.admin == true {
                Button {
                    viewModel.toggleThreadVisibility()
                } label: {
                    ActionImage(systemName: viewModel.thread?.isPrivate == true ? "lock.fill" : "lock.open.fill")
                        .foregroundColor(viewModel.thread?.isPrivate ?? false ? .green : .blue)
                }
            }

            Button {} label: {
                ActionImage(systemName: "magnifyingglass")
            }
        }
        .padding([.leading, .trailing])
        .buttonStyle(.bordered)
        .foregroundColor(.blue)

        if viewModel.showInfoGroupBox {
            VStack {
                if !viewModel.isInMyContact {
                    SectionItem(title: "General.addToContact", systemName: "person.badge.plus") {
                        viewModel.showAddToContactSheet.toggle()
                    }
                }

                if let phone = viewModel.cellPhoneNumber {
                    SectionItem(title: phone, systemName: "doc.on.doc") {
                        viewModel.copyPhone()
                    }
                }

                if viewModel.canBlock {
                    SectionItem(title: "General.block", systemName: "hand.raised.slash") {
                        viewModel.blockUnBlock()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding([.leading, .trailing])
        }
    }
}

struct TabDetail: View {
    let viewModel: DetailViewModel

    var body: some View {
        if let thread = viewModel.thread, let participantViewModel = viewModel.participantViewModel {
            VStack(spacing: 0) {
                TabViewsContainer(thread: thread, selectedTabIndex: 0)
                    .background(.ultraThickMaterial)
                    .environmentObject(participantViewModel)
            }
            .cornerRadius(12)
            .padding()
        }
    }
}

struct ActionImage: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
            .padding()
            .transition(.asymmetric(insertion: .scale.animation(.easeInOut(duration: 2)), removal: .scale.animation(.easeInOut(duration: 2))))
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
        AppState.shared.navViewModel?.threadViewModel = .init()
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
