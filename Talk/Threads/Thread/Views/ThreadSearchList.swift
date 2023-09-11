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
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var searchText: String

    var body: some View {
        if viewModel.isInSearchMode, viewModel.searchedMessages.count > 0 {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.searchedMessages) { message in
                        SearchMessageRow()
                            .environmentObject(MessageRowViewModel(message: message, viewModel: viewModel))
                            .onAppear {
                                if message == viewModel.searchedMessages.last {
                                    viewModel.searchInsideThread(text: searchText, offset: viewModel.searchedMessages.count)
                                }
                            }
                    }
                }
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            .background(.ultraThickMaterial)
        } else if viewModel.isInSearchMode {
            ZStack {
                Text("General.nothingFound")
                    .font(.iransansTitle)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(.ultraThickMaterial)
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
        vm.searchedMessages = MockData.generateMessages(count: 15)
        vm.objectWillChange.send()
        return vm
    }

    static var previews: some View {
        ThreadSearchList(searchText: .constant("TEST"))
            .previewDisplayName("ThreadSearchList")
            .environmentObject(vm)
    }
}
