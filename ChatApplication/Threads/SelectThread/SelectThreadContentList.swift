//
//  SelectThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct SelectThreadContentList: View {
    @EnvironmentObject var viewModel: ThreadsViewModel
    @State var searechInsideThread: String = ""
    var onSelect: (Conversation) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            MultilineTextField("Search ...", text: $searechInsideThread, backgroundColor: Color.gray.opacity(0.2))
                .cornerRadius(16)
                .noSeparators()
                .onChange(of: searechInsideThread) { _ in
                    viewModel.searchInsideAllThreads(text: searechInsideThread)
                }

            ForEach(viewModel.filtered) { thread in
                SelectThreadRow(thread: thread)
                    .onTapGesture {
                        onSelect(thread)
                        dismiss()
                    }
                    .onAppear {
                        if viewModel.filtered.last == thread {
                            viewModel.loadMore()
                        }
                    }
            }
        }
        .navigationTitle("Select Thread")
        .listStyle(.plain)
    }
}

struct SelectThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = ThreadsViewModel()
        SelectThreadContentList { _ in
        }
        .onAppear {}
        .environmentObject(vm)
        .environmentObject(appState)
    }
}
