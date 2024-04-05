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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollViewReader { scrollProxy in
            ThreadHistoryVStack()
                .background(ThreadbackgroundView(threadId: viewModel.threadId))
                .overlay(alignment: .bottom) {
                    VStack {
//                        MoveToBottomButton()
                        SendContainerOverButtons()
                    }
                }
                .task {
                    viewModel.historyVM.start()
                    /// It will lead to a memory leak and so many other crashes like:
                    /// 1- In context menus almost every place we will see crashes.
                    /// 2- If we remove this section, the background won't work.
                    /// 3- Don't use the group list style it will prevent the background from being shown.
                    /// 4- On iPadOS if we switch between threads threadViewModel will stay in the memory even if we press the back button or select another thread. However, by canceling observers we won't have any conflict, and after two more switch threads the app will release the object.
                    UICollectionViewCell.appearance().backgroundView = UIView()
                    UITableViewHeaderFooterView.appearance().backgroundView = UIView()
                }
        }
        .simultaneousGesture(tap.simultaneously(with: drag))
        .navigationBarBackButtonHidden(true)
        .background(Color.App.textSecondary.opacity(0.1).edgesIgnoringSafeArea(.bottom))
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
                AudioPlayerView(threadVM: viewModel)
            }
        }
        .background(threadWidthSetter)
        .onReceive(viewModel.$dismiss) { newValue in
            onDismiss(dismiss: newValue)
        }
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? { DropProposal(operation: .copy) }

    func performDrop(info: DropInfo) -> Bool {
        viewModel.storeDropItems(info.itemProviders(for: [.item]))
        return true
    }

    private var threadWidthSetter: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                DispatchQueue.main.async {
                    ThreadViewModel.threadWidth = reader.size.width
                }
            }
        }
    }

    private func onDismiss(dismiss: Bool) {
        if dismiss {
            AppState.shared.objectsContainer.navVM.remove(threadId: thread.id)
            self.dismiss()
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { newValue in
                viewModel.onDragged(translation: newValue.translation, startLocation: newValue.location)
            }
    }

    private var tap: some Gesture {
        TapGesture()
            .onEnded { _ in
                hideKeyboardOnTapOrDrag()
            }
    }

    private func hideKeyboardOnTapOrDrag() {
        if viewModel.searchedMessagesViewModel.searchText.isEmpty {
            NotificationCenter.cancelSearch.post(name: .cancelSearch, object: true)
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        viewModel.historyVM.sections.flatMap{$0.vms}.filter{ $0.showReactionsOverlay == true }.forEach { rowViewModel in
            rowViewModel.showReactionsOverlay = false
            rowViewModel.animateObjectWillChange()
        }
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
        ThreadView(viewModel: .init(thread: .init(id: 1)))
            .environmentObject(ThreadViewModel(thread: MockData.thread))
            .environmentObject(AppState.shared)
            .onAppear {
                //                vm.toggleRecording()
                //                vm.setReplyMessage(MockData.message)
                //                vm.setForwardMessage(MockData.message)
            }
    }
}
