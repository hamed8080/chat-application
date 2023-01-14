//
//  DetailView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import Photos
import SwiftUI

struct DetailView: View {
    @EnvironmentObject var viewModel: DetailViewModel
    @State var addToContactSheet: Bool = false
    @State var title: String = ""
    @State var threadDescription: String = ""
    @State var isInEditMode = false
    @State var showImagePicker: Bool = false
    @State private var image: UIImage?
    @State private var assetResource: [PHAssetResource]?
    @State var searchText: String = ""

    var body: some View {
        List {
            VStack(alignment: .center, spacing: 12) {
                viewModel.imageLoader?.imageView
                    .font(.system(size: 16).weight(.heavy))
                    .foregroundColor(.white)
                    .frame(width: 128, height: 128)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(64)
                    .onTapGesture {
                        if isInEditMode, viewModel.thread?.canEditInfo == true {
                            showImagePicker = true
                        }
                    }

                let bgColor = isInEditMode ? Color.primary.opacity(0.08) : Color.clear
                if viewModel.thread?.canEditInfo == true {
                    PrimaryTextField(title: "Title", textBinding: $title, keyboardType: .alphabet, backgroundColor: bgColor)
                        .disabled(!isInEditMode)
                        .multilineTextAlignment(.center)
                        .font(.headline.bold())
                        .onAppear {
                            title = viewModel.thread?.title ?? ""
                            threadDescription = viewModel.thread?.description ?? ""
                        }
                } else {
                    Text(viewModel.title)
                        .font(.title2.bold())
                }

                if viewModel.thread?.canEditInfo == true {
                    PrimaryTextField(title: "Description", textBinding: $threadDescription, keyboardType: .alphabet, backgroundColor: bgColor)
                        .disabled(!isInEditMode)
                        .multilineTextAlignment(.center)
                        .font(.caption)
                }

                if let notSeenString = viewModel.notSeenString {
                    Text(notSeenString)
                        .font(.caption)
                }
            }
            .noSeparators()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)

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
                        viewModel.createThread()
                    } label: {
                        ActionImage(systemName: "phone.fill")
                    }
                    Button {
                        viewModel.createThread()
                    } label: {
                        ActionImage(systemName: "video.fill")
                    }

                    Button {
                        viewModel.toggleMute()
                    } label: {
                        ActionImage(systemName: "bell.fill")
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
                            if !viewModel.isInMyContact {
                                Divider()
                            }
                        }
                        if !viewModel.isInMyContact {
                            SectionItem(title: "Add To contacts", systemName: "person.badge.plus") {
                                addToContactSheet.toggle()
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

            if let thread = viewModel.thread {
                Section {
                    TabViewsContainer(thread: thread, selectedTabIndex: 0)
                }
                .noSeparators()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("Info")
        .listStyle(.plain)
        .sheet(isPresented: $addToContactSheet) {
            AddOrEditContactView()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                self.image = image
                self.assetResource = assestResources
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                VStack(alignment: .center) {
                    if viewModel.thread?.canEditInfo == true {
                        Button {
                            if isInEditMode {
                                // submited
                                viewModel.updateThreadInfo(title, threadDescription, image: image, assetResources: assetResource)
                            }
                            isInEditMode.toggle()
                        } label: {
                            Text(isInEditMode ? "Done" : "Edit")
                        }
                    }
                }
            }
        }
        .animation(.interactiveSpring(), value: isInEditMode)
    }
}

struct ActionImage: View {
    let systemName: String

    var body: some View {
        SwiftUI.Image(systemName: systemName)
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
        DetailView()
            .environmentObject(DetailViewModel(thread: MockData.thread, contact: MockData.contact, user: nil))
    }
}
