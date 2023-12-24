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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ThreadMessagesList(viewModel: viewModel)
            .navigationBarBackButtonHidden(true)
            .background(Color.App.grayHalf.opacity(0.1).edgesIgnoringSafeArea(.bottom))            
            .background(SheetEmptyBackground())
            .onDrop(of: [.image], delegate: self)
            .safeAreaInset(edge: .bottom) {
                ThreadEmptySpaceView()                    
            }
            .overlay(alignment: .bottom) {
                SendContainerOverlayView()                    
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    ThreadMainToolbar(viewModel: viewModel)
                    ThreadPinMessage(threadVM: viewModel)
                    AudioPlayerView(threadVM: viewModel)
                    ThreadSearchList(threadVM: viewModel)                        
                }
            }
            .background {
                GeometryReader { reader in
                    Color.clear.onAppear {
                        DispatchQueue.main.async {
                            ThreadViewModel.threadWidth = reader.size.width
                        }
                    }
                }
            }
            .onAppear {
                viewModel.historyVM.startFetchingHistory()
                threadsVM.clearAvatarsOnSelectAnotherThread()
            }
            .onReceive(viewModel.$dismiss) { newValue in
                if newValue {
                    AppState.shared.navViewModel?.remove(type: ThreadViewModel.self, threadId: thread.id)
                    dismiss()
                }
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
