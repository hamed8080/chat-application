//
//  DetailView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import Photos
import SwiftUI

struct DetailView: View {
    @StateObject var viewModel: DetailViewModel

    var body: some View {
        List {
            InfoView()
            Section {
                HStack(spacing: 32) {
                    Spacer()
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

                    Spacer()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.blue)
            }
            .noSeparators()

            if viewModel.showInfoGroupBox {
                GroupBox {
                    Section {
                        if let bio = viewModel.bio {
                            Text(bio)
                                .font(.iransansCaption)
                                .foregroundColor(.gray)
                            if !viewModel.isInMyContact {
                                Divider()
                            }
                        }
                        if !viewModel.isInMyContact {
                            SectionItem(title: "Add To contacts", systemName: "person.badge.plus") {
                                viewModel.addToContactSheet.toggle()
                            }
                            if viewModel.cellPhoneNumber != nil {
                                Divider()
                            }
                        }
                        if let phone = viewModel.cellPhoneNumber {
                            SectionItem(title: phone, systemName: "doc.on.doc") {
                                viewModel.copyPhone()
                            }
                            if viewModel.canBlock {
                                Divider()
                            }
                        }

                        if viewModel.canBlock {
                            SectionItem(title: "Block", systemName: "hand.raised.slash") {
                                viewModel.blockUnBlock()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                .noSeparators()
            }

            if let thread = viewModel.thread, let participantViewModel = viewModel.participantViewModel {
                Section {
                    TabViewsContainer(thread: thread, selectedTabIndex: 0)
                        .environmentObject(participantViewModel)
                }
                .noSeparators()
            }
        }
        .environmentObject(viewModel)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("Info")
        .listStyle(.plain)
        .sheet(isPresented: $viewModel.addToContactSheet) {
            AddOrEditContactView()
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
                            Text(viewModel.isInEditMode ? "Done" : "Edit")
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: viewModel.thread?.isPrivate == true)
        .animation(.interactiveSpring(), value: viewModel.isInEditMode)
        .animation(.easeInOut, value: viewModel.thread?.mute)
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
    }
}

struct InfoView: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            ImageLaoderView(url: viewModel.url, metaData: viewModel.thread?.metadata, userName: viewModel.title)
                .id("\(viewModel.url ?? "")\(viewModel.thread?.id ?? 0)")
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 128, height: 128)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(64)
                .onTapGesture {
                    if viewModel.isInEditMode, viewModel.thread?.canEditInfo == true {
                        viewModel.showImagePicker = true
                    }
                }

            let bgColor = viewModel.isInEditMode ? Color.primary.opacity(0.08) : Color.clear
            if viewModel.thread?.canEditInfo == true {
                PrimaryTextField(title: "Title", textBinding: $viewModel.editTitle, keyboardType: .alphabet, backgroundColor: bgColor)
                    .disabled(!viewModel.isInEditMode)
                    .multilineTextAlignment(.center)
                    .font(.iransansBody)
            } else {
                Text(viewModel.title)
                    .font(.iransansBoldTitle)
            }

            if viewModel.thread?.canEditInfo == true {
                PrimaryTextField(title: "Description", textBinding: $viewModel.threadDescription, keyboardType: .alphabet, backgroundColor: bgColor)
                    .disabled(!viewModel.isInEditMode)
                    .multilineTextAlignment(.center)
                    .font(.caption)
            }

            if let notSeenString = viewModel.notSeenString {
                Text(notSeenString)
                    .font(.iransansCaption3)
            }
        }
        .noSeparators()
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
    }
}

struct ActionImage: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .padding()
            .transition(.asymmetric(insertion: .scale.animation(.easeInOut(duration: 2)), removal: .scale.animation(.easeInOut(duration: 2))))
    }
}

struct SectionItem: View {
    let title: String
    let systemName: String
    var action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.blue)
            Spacer()
            Button {
                action()
            } label: {
                ActionImage(systemName: systemName)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(viewModel: DetailViewModel(thread: MockData.thread, contact: MockData.contact, user: nil))
    }
}
