//
//  ThreadView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import ChatModels
import Combine
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels

struct ThreadView: View, DropDelegate {
    private var thread: Conversation { viewModel.thread }
    let viewModel: ThreadViewModel
    let threadsVM: ThreadsViewModel
    @State var searchMessageText: String = ""

    var body: some View {
        ThreadMessagesList(viewModel: viewModel)
            .id(thread.id)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationTitle(thread.computedTitle)
            .background(Color.App.grayHalf.opacity(0.1).edgesIgnoringSafeArea(.bottom))
            .environmentObject(viewModel)
            .environmentObject(threadsVM)
            .searchable(text: $searchMessageText, placement: .toolbar, prompt: "General.searchHere")
            .background(SheetEmptyBackground())
            .onDrop(of: [.image], delegate: self)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SendContainer(viewModel: viewModel)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    ThreadPinMessage(threadVM: viewModel)
                    AudioPlayerView()
                }
            }
            .overlay {
                ThreadSearchList(threadVM: viewModel, searchText: $searchMessageText)
                    .environmentObject(viewModel)
                    .environmentObject(viewModel.searchedMessagesViewModel)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    NavigationBackButton {
                        AppState.shared.navViewModel?.remove(type: ThreadViewModel.self, threadId: thread.id)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarLeading) {
                    ThreadLeadingToolbar(viewModel: viewModel)
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ThreadViewTrailingToolbar(viewModel: viewModel)
                }

                ToolbarItem(placement: .principal) {
                    ThreadViewCenterToolbar(viewModel: viewModel)
                }
            }
            .onChange(of: searchMessageText) { value in
                viewModel.searchedMessagesViewModel.searchInsideThread(text: value)
            }
            .onAppear {
                viewModel.startFetchingHistory()
                threadsVM.clearAvatarsOnSelectAnotherThread()
            }
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? { DropProposal(operation: .copy) }

    func performDrop(info: DropInfo) -> Bool {
        viewModel.storeDropItems(info.itemProviders(for: [.item]))
        return true
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var vm: ThreadViewModel {
        let vm = ThreadViewModel(thread: MockData.thread)
//        vm.searchedMessages = MockData.generateMessages(count: 15)
        vm.objectWillChange.send()
        return vm
    }

    static var previews: some View {
        ThreadView(viewModel: .init(thread: .init(id: 1)), threadsVM: ThreadsViewModel())
            .environmentObject(ThreadViewModel(thread: MockData.thread))
            .environmentObject(AppState.shared)
            .onAppear {
                //                vm.toggleRecording()
                //                vm.setReplyMessage(MockData.message)
                //                vm.setForwardMessage(MockData.message)
                vm.isInEditMode = false
            }
    }
}
