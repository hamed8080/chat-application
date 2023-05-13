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
    @Binding var searchMessageText: String

    var body: some View {
        if searchMessageText.count > 0, viewModel.searchedMessages.count > 0 {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.searchedMessages) { message in
                        SearchMessageRow(message: message)
                            .onAppear {
                                if message == viewModel.searchedMessages.last {
                                    viewModel.searchInsideThread(text: searchMessageText, offset: viewModel.searchedMessages.count)
                                }
                            }
                    }
                }
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            .background(.ultraThickMaterial)
        } else if searchMessageText.count > 0 {
            ZStack {
                Text("Nothing found.")
                    .font(.iransansTitle)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(.ultraThickMaterial)
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
        ThreadSearchList(searchMessageText: searchMessageText)
            .previewDisplayName("ThreadSearchList")
            .environmentObject(vm)
    }
}
