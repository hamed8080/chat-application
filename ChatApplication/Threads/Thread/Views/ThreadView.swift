//
//  ThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

struct ThreadView: View, DropDelegate {
    let thread: Conversation
    @StateObject var viewModel = ThreadViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @State var isInEditMode: Bool = false
    @State var deleteDialaog: Bool = false
    @State var searchMessageText: String = ""
    var sheetBinding: Binding<Bool> { Binding(get: { viewModel.sheetType != nil }, set: { _ in }) }

    var body: some View {
        ThreadMessagesList(isInEditMode: $isInEditMode)
            .id(thread.id)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.thread?.computedTitle ?? "")
            .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
            .environmentObject(viewModel)
            .environmentObject(threadsVM)
            .searchable(text: $searchMessageText, placement: .toolbar, prompt: "Search inside this chat")
            .dialog("Delete selected messages", "Are you sure you want to delete all selected messages?", "trash.fill", $deleteDialaog) { _ in
                viewModel.deleteMessages(viewModel.selectedMessages)
                viewModel.isInEditMode = false
            }
            .overlay {
                SendContainer(deleteMessagesDialog: $deleteDialaog)
                    .environmentObject(viewModel)
            }
            .overlay {
                ThreadSearchList(searchMessageText: $searchMessageText)
                    .environmentObject(viewModel)
            }
            .overlay {
                ThreadPinMessage()
                    .environmentObject(viewModel)
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
                    trailingToolbar
                }

                ToolbarItem(placement: .principal) {
                    centerToolbarTitle
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
            }
            .onReceive((viewModel.exportMessagesVM as! ExportMessagesViewModel).$filePath) { filePath in
                if filePath != nil {
                    viewModel.sheetType = .exportMessagesFile
                }
            }
            .onAppear {
                viewModel.setup(thread: thread, readOnly: false, threadsViewModel: threadsVM)
                if !viewModel.isFetchedServerFirstResponse {
                    viewModel.getHistory()
                }
                appState.activeThreadId = thread.id
            }
            .sheet(isPresented: sheetBinding, onDismiss: onDismiss) {
                ThreadSheetView(sheetBinding: sheetBinding)
                    .environmentObject(viewModel)
                    .environmentObject(ActionSheetViewModel(threadViewModel: viewModel))
            }
            .onDrop(of: [.image], delegate: self)
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? { DropProposal(operation: .copy) }

    func performDrop(info: DropInfo) -> Bool {
        viewModel.storeDropItems(info.itemProviders(for: [.item]))
        viewModel.sheetType = .dropItems
        return true
    }

    func onDismiss() {
        viewModel.exportMessagesVM.deleteFile()
        viewModel.dropItems.removeAll()
        viewModel.sheetType = nil
    }

    var centerToolbarTitle: some View {
        VStack(alignment: .center) {
            Text(viewModel.thread?.computedTitle ?? "")
                .fixedSize()
                .font(.headline)

            if appState.connectionStatus != .connected {
                ConnectionStatusToolbar()
            } else if let signalMessageText = viewModel.signalMessageText {
                Text(signalMessageText)
                    .foregroundColor(.textBlueColor)
                    .font(.footnote.bold())
            } else if let participantsCount = viewModel.thread?.participantCount {
                Text("Members \(participantsCount)")
                    .fixedSize()
                    .foregroundColor(Color.gray)
                    .font(.footnote)
            }
        }
    }

    @ViewBuilder var trailingToolbar: some View {
        NavigationLink {
            DetailView(viewModel: DetailViewModel(thread: viewModel.thread))
        } label: {
            ImageLaoderView(url: viewModel.thread?.computedImageURL, userName: viewModel.thread?.title)
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(16)
                .cornerRadius(18)
        }

        Menu {
            Button {
                viewModel.sheetType = .datePicker
            } label: {
                Label {
                    Text("Export")
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .scaledToFit()
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var vm: ThreadViewModel {
        let vm = ThreadViewModel()
        vm.searchedMessages = MockData.generateMessages(count: 15)
        vm.objectWillChange.send()
        return vm
    }

    static var previews: some View {
        ThreadView(thread: MockData.thread)
            .environmentObject(AppState.shared)
            .onAppear {
                vm.setup(thread: MockData.thread)
                //                vm.toggleRecording()
                //                vm.setReplyMessage(MockData.message)
                //                vm.setForwardMessage(MockData.message)
                vm.isInEditMode = false
            }
    }
}
