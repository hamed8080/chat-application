//
//  ThreadContentList.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadContentList: View {
    let container: ObjectsContainer
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @State private var searchText: String = ""
    @State var selectedThreadId: Conversation.ID?
    @EnvironmentObject var navVM: NavigationModel
    private var sheetBinding: Binding<Bool> { Binding(get: { threadsVM.sheetType != nil }, set: { _ in }) }

    var body: some View {
        List(threadsVM.filtered, selection: $navVM.selectedThreadId) { thread in
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
            ListLoadingView(isLoading: $threadsVM.isLoading)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "General.searchHere")
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
        .navigationTitle(String(localized: .init(threadsVM.title)))
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
                Label("ThreadList.Toolbar.startNewChat", systemImage: "bubble.left.and.bubble.right.fill")
            }

            Button {
                threadsVM.sheetType = .joinToPublicThread
            } label: {
                Label("ThreadList.Toolbar.joinToPublicThread", systemImage: "door.right.hand.open")
            }

            // Send a message to a user without creating a new contact. Directly by their userName or cellPhone number.
            Button {
                threadsVM.sheetType = .fastMessage
            } label: {
                Label("ThreadList.Toolbar.fastMessage", systemImage: "arrow.up.circle.fill")
            }

            Button {} label: {
                Label("ThreadList.Toolbar.createABot", systemImage: "face.dashed.fill")
            }
        } label: {
            Label("ThreadList.Toolbar.startNewChat", systemImage: "plus.square")
        }

        Menu {
            Button {
                threadsVM.selectedFilterThreadType = nil
                threadsVM.refresh()
            } label: {
                if threadsVM.selectedFilterThreadType == nil {
                    Image(systemName: "checkmark")
                }
                Text("General.all")
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
                        Text(.init(localized: .init(type)))
                    }
                }
            }
        } label: {
            Label("ThreadList.Toolbar.filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

private struct Preview: View {
    @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)

    var body: some View {
        NavigationStack {
            ThreadContentList(container: container)
                .environmentObject(container)
                .environmentObject(container.audioPlayerVM)
                .environmentObject(container.threadsVM)
                .environmentObject(AppState.shared)
                .onAppear {
                    container.threadsVM.title = "Tab.chats"
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
