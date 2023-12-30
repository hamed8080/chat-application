//
//  ThreadSearchList.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadSearchList: View {
    let threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: ThreadSearchMessagesViewModel

    var body: some View {
        if viewModel.isInSearchMode, viewModel.searchedMessages.count > 0 {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.searchedMessages) { message in
                        SearchMessageRow(viewModel: .init(message: message, viewModel: threadVM))
                            .environmentObject(MessageRowViewModel(message: message, viewModel: threadVM))
                            .onAppear {
                                if message == viewModel.searchedMessages.last {
                                    viewModel.loadMore()
                                }
                            }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            .background(Color.App.bgPrimary.ignoresSafeArea())
            .environment(\.layoutDirection, .leftToRight)
        } else if viewModel.isInSearchMode {
            ZStack {
                if viewModel.isLoading {
                    ListLoadingView(isLoading: $viewModel.isLoading)
                } else if viewModel.isInSearchMode {
                    Text("General.nothingFound")
                        .font(.iransansTitle)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.App.bgPrimary.ignoresSafeArea())
            .transition(.opacity)
        }
    }
}

struct ThreadSearchList_Previews: PreviewProvider {
    static var searchMessageText: Binding<String> {
        Binding(get: { "Hello" }, set: { _ in })
    }

    static var vm: ThreadViewModel {
        let vm = ThreadViewModel(thread: Conversation())
//        vm.searchedMessages = MockData.generateMessages(count: 15)
        vm.objectWillChange.send()
        return vm
    }

    static var previews: some View {
        ThreadSearchList(threadVM: vm)
            .previewDisplayName("ThreadSearchList")
            .environmentObject(vm)
    }
}
