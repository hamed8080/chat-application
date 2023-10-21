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
    @EnvironmentObject var viewModel: ThreadViewModel
    let threadsVM: ThreadsViewModel
    @State var isInEditMode: Bool = false
    @State var deleteDialaog: Bool = false
    @State var searchMessageText: String = ""
    var sheetBinding: Binding<Bool> { Binding(get: { viewModel.sheetType != nil }, set: { _ in }) }
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ThreadMessagesList(viewModel: viewModel)
            .id(thread.id)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationTitle(thread.computedTitle)
            .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
            .environmentObject(viewModel)
            .environmentObject(threadsVM)
            .searchable(text: $searchMessageText, placement: .toolbar, prompt: "General.searchHere")
            .customDialog(isShowing: $deleteDialaog) {
                DeleteMessageDialog(viewModel: viewModel, showDialog: $deleteDialaog)
            }
            .overlay {
                SendContainer(viewModel: viewModel, deleteMessagesDialog: $deleteDialaog)
            }
            .overlay {
                ThreadSearchList(searchText: $searchMessageText)
                    .environmentObject(viewModel)
            }
            .overlay {
                ThreadPinMessage(threadVM: viewModel)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    NavigationBackButton {
                        AppState.shared.navViewModel?.remove(type: ThreadViewModel.self, threadId: thread.id)
                    }
                }

                if UIDevice.current.userInterfaceIdiom == .pad && sizeClass != .compact {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            NotificationCenter.default.post(name: Notification.Name.closeSideBar, object: nil)
                        } label : {
                            Image(systemName: "sidebar.leading")
                                .foregroundStyle(Color.main)
                        }
                    }
                }

                if thread.type == .channel {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Image(systemName: "megaphone.fill")
                            .resizable()
                            .foregroundColor(Color.main)
                            .frame(width: 16, height: 16)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ThreadViewTrailingToolbar(viewModel: viewModel)
                }

                ToolbarItem(placement: .principal) {
                    ThreadViewCenterToolbar(viewModel: viewModel)
                }
            }
            .onChange(of: searchMessageText) { value in
                viewModel.searchInsideThread(text: value)
            }
            .onChange(of: viewModel.isInEditMode) { _ in
                isInEditMode = viewModel.isInEditMode
            }
            .onChange(of: viewModel.editMessage) { _ in
                viewModel.textMessage = viewModel.editMessage?.message ?? ""
                viewModel.animateObjectWillChange()
            }
            .onAppear {
                viewModel.startFetchingHistory()
                threadsVM.clearAvatarsOnSelectAnotherThread()
            }
            .sheet(isPresented: sheetBinding) {
                ThreadSheetView(sheetBinding: sheetBinding)
                    .environmentObject(viewModel.sheetViewModel)
            }
            .onDrop(of: [.image], delegate: self)
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? { DropProposal(operation: .copy) }

    func performDrop(info: DropInfo) -> Bool {
        viewModel.storeDropItems(info.itemProviders(for: [.item]))
        viewModel.sheetType = .dropItems
        viewModel.animateObjectWillChange()
        return true
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var vm: ThreadViewModel {
        let vm = ThreadViewModel(thread: MockData.thread)
        vm.searchedMessages = MockData.generateMessages(count: 15)
        vm.objectWillChange.send()
        return vm
    }

    static var previews: some View {
        ThreadView(threadsVM: ThreadsViewModel())
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
