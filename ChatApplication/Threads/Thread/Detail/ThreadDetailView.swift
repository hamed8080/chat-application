//
//  ThreadDetailView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import Photos
import SwiftUI

struct ThreadDetailView: View {
    @EnvironmentObject
    var viewModel: ThreadViewModel

    @State
    var threadTitle: String = ""

    @State
    var threadDescription: String = ""

    @State
    var isInEditMode = false

    @State
    var showImagePicker: Bool = false

    @State private var image: UIImage?
    @State private var assetResource: [PHAssetResource]?

    var body: some View {
        let thread = viewModel.thread

        GeometryReader { reader in
            VStack {
                List {
                    VStack {
                        Avatar(
                            url: thread.image,
                            userName: thread.title?.uppercased(),
                            style: .init(size: 128, textSize: 48),
                            metadata: thread.metadata
                        )
                        .onTapGesture {
                            if isInEditMode {
                                showImagePicker = true
                            }
                        }

                        PrimaryTextField(title: "Title", textBinding: $threadTitle, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.08))
                            .disabled(!isInEditMode)
                            .multilineTextAlignment(.center)
                            .font(.headline.bold())

                        if !threadDescription.isEmpty || isInEditMode {
                            PrimaryTextField(title: "Description", textBinding: $threadDescription, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.08))
                                .disabled(!isInEditMode)
                                .multilineTextAlignment(.center)
                                .font(.caption)
                        }

                        if let lastSeen = ContactRow.getDate(notSeenDuration: thread.participants?.first?.notSeenDuration) {
                            Text(lastSeen)
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }

                        HStack {
                            Spacer()
                            ActionButton(iconSfSymbolName: "bell", iconColor: .blue, taped: {
                                viewModel.toggleMute()
                            })

                            ActionButton(iconSfSymbolName: "magnifyingglass", iconColor: .blue, taped: {
                                viewModel.searchInsideThreadMessages("")
                            })

                            if let type = thread.type, type == .normal {
                                ActionButton(iconSfSymbolName: "hand.raised.slash", iconColor: .blue, taped: {})
                            }
                            Spacer()
                        }
                        .padding(SwiftUI.EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(16)
                    }
                    .noSeparators()
                    if let thread = viewModel.thread {
                        Section {
                            TabViewsContainer(thread: thread, selectedTabIndex: 0)
                                .ignoresSafeArea(.all, edges: [.bottom])
                                .frame(minHeight: reader.size.height + reader.safeAreaInsets.bottom)
                                .noSeparators()
                                .listRowInsets(.init())
                        }
                    }
                }
                .ignoresSafeArea(.all, edges: [.bottom])
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                self.image = image
                self.assetResource = assestResources
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            threadTitle = viewModel.thread.title ?? ""
            threadDescription = viewModel.thread.description ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                VStack(alignment: .center) {
                    Button {
                        if isInEditMode {
                            // submited
                            viewModel.updateThreadInfo(threadTitle, threadDescription, image: image, assetResources: assetResource)
                        }
                        isInEditMode.toggle()
                    } label: {
                        Text(isInEditMode ? "Done" : "Edit")
                    }
                }
            }
        }
        .animation(.interactiveSpring(), value: isInEditMode)
    }
}

struct ThreadDetailView_Previews: PreviewProvider {
    static var vm: ThreadViewModel {
        let thread = MockData.thread
        let vm = ThreadViewModel(thread: thread)
        thread.title = "Test Thread title"
        thread.description = "Test Thread Description with slightly long text"
        return vm
    }

    static var previews: some View {
        ThreadDetailView()
            .environmentObject(vm)
            .environmentObject(AppState.shared)
            .onAppear {
                vm.setupPreview()
            }
    }
}
