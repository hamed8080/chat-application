//
//  ThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import ChatAppModels
import ChatAppUI
import ChatAppViewModels
import ChatModels
import Combine
import SwiftUI

struct ThreadView: View, DropDelegate {
    private var thread: Conversation { viewModel.thread }
    @StateObject var viewModel: ThreadViewModel
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @State var isInEditMode: Bool = false
    @State var deleteDialaog: Bool = false
    @State var searchMessageText: String = ""
    var sheetBinding: Binding<Bool> { Binding(get: { viewModel.sheetType != nil }, set: { _ in }) }

    var body: some View {
        ThreadMessagesList(viewModel: viewModel)
            .id(thread.id)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(thread.computedTitle)
            .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
            .environmentObject(viewModel)
            .environmentObject(threadsVM)
            .searchable(text: $searchMessageText, placement: .toolbar, prompt: "Search inside this chat")
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
                if thread.type == .channel {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Image(systemName: "megaphone.fill")
                            .resizable()
                            .foregroundColor(.blue)
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
                viewModel.animatableObjectWillChange()
            }
            .onReceive((viewModel.exportMessagesVM as! ExportMessagesViewModel).$filePath) { filePath in
                if filePath != nil {
                    viewModel.sheetType = .exportMessagesFile
                    viewModel.animatableObjectWillChange()
                }
            }
            .onAppear {
                viewModel.startFetchingHistory()
            }
            .sheet(isPresented: sheetBinding, onDismiss: onDismiss) {
                ThreadSheetView(sheetBinding: sheetBinding)
                    .environmentObject(viewModel.sheetViewModel)
            }
            .onDrop(of: [.image], delegate: self)
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? { DropProposal(operation: .copy) }

    func performDrop(info: DropInfo) -> Bool {
        viewModel.storeDropItems(info.itemProviders(for: [.item]))
        viewModel.sheetType = .dropItems
        viewModel.animatableObjectWillChange()
        return true
    }

    func onDismiss() {
        viewModel.exportMessagesVM.deleteFile()
        viewModel.dropItems.removeAll()
        viewModel.sheetType = nil
        viewModel.animatableObjectWillChange()
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
        ThreadView(viewModel: ThreadViewModel(thread: MockData.thread))
            .environmentObject(AppState.shared)
            .onAppear {
                //                vm.toggleRecording()
                //                vm.setReplyMessage(MockData.message)
                //                vm.setForwardMessage(MockData.message)
                vm.isInEditMode = false
            }
    }
}
