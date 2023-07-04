//
//  ThreadSearchList.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import ChatAppUI
import ChatAppViewModels
import SwiftUI

struct ThreadSearchList: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    var searchText: String { viewModel.searchMessageText }

    var body: some View {
        if searchText.count > 0, viewModel.searchedMessages.count > 0 {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.searchedMessages) { message in
                        SearchMessageRow(message: message)
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
            .animation(.easeInOut, value: viewModel.searchMessageText)
            .animation(.easeInOut, value: viewModel.searchedMessages.count)
        } else if searchText.count > 0 {
            ZStack {
                Text("Nothing found.")
                    .font(.iransansTitle)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(.ultraThickMaterial)
            .animation(.easeInOut, value: viewModel.searchMessageText)
            .transition(.opacity)
        }
    }
}

struct ThreadSearchList_Previews: PreviewProvider {
    static var searchMessageText: Binding<String> {
        Binding(get: { "Hello" }, set: { _ in })
    }

    static var vm: ThreadViewModel {
        let vm = ThreadViewModel()
        vm.searchedMessages = MockData.generateMessages(count: 15)
        vm.objectWillChange.send()
        return vm
    }

    static var previews: some View {
        ThreadSearchList()
            .previewDisplayName("ThreadSearchList")
            .environmentObject(vm)
    }
}
