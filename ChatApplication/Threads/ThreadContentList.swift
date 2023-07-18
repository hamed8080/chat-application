//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ThreadContentList: View {
    @EnvironmentObject var container: ObjectsContainer
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @State private var searchText: String = ""
    private var sheetBinding: Binding<Bool> { Binding(get: { threadsVM.sheetType != nil }, set: { _ in }) }

    var body: some View {
        List(threadsVM.filtered, selection: $container.navVM.selectedThreadId) { thread in
            NavigationLink(value: thread.id) {
                ThreadRow(thread: thread)
                    .onAppear {
                        if self.threadsVM.filtered.last == thread {
                            threadsVM.loadMore()
                        }
                    }
            }
            .listRowBackground(container.navVM.selectedThreadId == thread.id ? Color.orange.opacity(0.5) : Color(UIColor.systemBackground))
        }
        .safeAreaInset(edge: .top) {
            AudioPlayerView()
        }
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $container.threadsVM.isLoading)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search...")
        .onChange(of: searchText) { searchText in
            threadsVM.searchText = searchText
            threadsVM.getThreads()
        }
        .animation(.easeInOut, value: threadsVM.filtered)
        .animation(.easeInOut, value: threadsVM.isLoading)
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ThreadsTrailingToolbarView(threadsVM: threadsVM)
            }

            ToolbarItem(placement: .principal) {
                ConnectionStatusToolbar()
            }
        }
        .navigationTitle(threadsVM.title)
        .sheet(isPresented: sheetBinding) {
            threadsVM.sheetType = nil
        } content: {
            ThreadsSheetFactoryView()
        }
    }
}

struct ThreadsTrailingToolbarView: View {
    let threadsVM: ThreadsViewModel

    var body: some View {
        trailingToolbarViews
    }

    @ViewBuilder var trailingToolbarViews: some View {
        Menu {
            Button {
                threadsVM.sheetType = .startThread
            } label: {
                Label("Start a new Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }

            Button {
                threadsVM.sheetType = .joinToPublicThread
            } label: {
                Label("Join a public Chat", systemImage: "door.right.hand.open")
            }

            // Send a message to a user without creating a new contact. Directly by their userName or cellPhone number.
            Button {
                threadsVM.sheetType = .fastMessage
            } label: {
                Label("Fast Messaage", systemImage: "arrow.up.circle.fill")
            }

            Button {} label: {
                Label("Create a new Bot", systemImage: "face.dashed.fill")
            }
        } label: {
            Label("Start new Chat", systemImage: "plus.square")
        }

        Menu {
            Button {
                threadsVM.selectedFilterThreadType = nil
                threadsVM.refresh()
            } label: {
                if threadsVM.selectedFilterThreadType == nil {
                    Image(systemName: "checkmark")
                }
                Text("All")
            }
            ForEach(ThreadTypes.allCases) { item in
                if let type = item.stringValue {
                    Button {
                        threadsVM.selectedFilterThreadType = item
                        threadsVM.refresh()
                    } label: {
                        if threadsVM.selectedFilterThreadType == item {
                            Image(systemName: "checkmark")
                        }
                        Text("\(type)")
                    }
                }
            }
        } label: {
            Label("Filter threads", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

private struct Preview: View {
    @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)

    var body: some View {
        NavigationStack {
            ThreadContentList()
                .environmentObject(container)
                .environmentObject(container.audioPlayerVM)
                .environmentObject(container.threadsVM)
                .environmentObject(AppState.shared)
                .onAppear {
                    container.threadsVM.title = "Chats"
                    container.threadsVM.appendThreads(threads: MockData.generateThreads(count: 5))
                    if let fileURL = Bundle.main.url(forResource: "new_message", withExtension: "mp3") {
                        container.audioPlayerVM.setup(fileURL: fileURL, ext: "mp3", title: "Note")
                        container.audioPlayerVM.toggle()
                    }
                }
        }
    }
}

struct ThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
}
