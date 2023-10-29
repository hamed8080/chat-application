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
    @State var selectedThreadId: Conversation.ID?
    @EnvironmentObject var navVM: NavigationModel
    private var sheetBinding: Binding<Bool> { Binding(get: { threadsVM.sheetType != nil }, set: { _ in }) }

    var body: some View {
        List(threadsVM.filtered) { thread in
            Button {
                navVM.append(thread: thread)
            } label: {
                ThreadRow(thread: thread)
                    .onAppear {
                        if self.threadsVM.filtered.last == thread {
                            threadsVM.loadMore()
                        }
                    }
            }
            .listRowInsets(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
            .listRowSeparatorTint(Color.App.separator)
            .listRowBackground(container.navVM.selectedThreadId == thread.id ? Color.App.primary.opacity(0.5) : thread.pin == true ? Color.App.bgTertiary : Color.App.bgPrimary)
        }
        .safeAreaInset(edge: .top) {
            AudioPlayerView()
        }
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $threadsVM.isLoading)
        }
        .animation(.easeInOut, value: threadsVM.filtered.count)
        .animation(.easeInOut, value: threadsVM.isLoading)
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 44)
        }
        .overlay(alignment: .top) {
            ToolbarView(
                title: "Tab.chats",
                searchPlaceholder: "General.searchHere",
                leadingViews: leadingViews,
                centerViews: centerViews,
                trailingViews: trailingViews
            ) { searchValue in
                threadsVM.searchText = searchValue
            }
        }
        .sheet(isPresented: sheetBinding) {
            threadsVM.sheetType = nil
        } content: {
            ThreadsSheetFactoryView()
        }
        .sheet(isPresented: $threadsVM.showStartConversationBuilder) {
            container.contactsVM.closeBuilder()
        } content: {
            StartThreadContactPickerView()
        }
    }

    var leadingViews: some View {
        EmptyView()
            .frame(width: 0, height: 0)
            .hidden()
    }

    var centerViews: some View {
        ConnectionStatusToolbar()
    }

    var trailingViews: some View {
        ThreadsTrailingToolbarView(threadsVM: threadsVM)
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
                threadsVM.showStartConversationBuilder.toggle()
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

//            Button {} label: {
//                Label("ThreadList.Toolbar.createABot", systemImage: "face.dashed.fill")
//            }
        } label: {
            ToolbarButtonItem(imageName: "plus.circle.fill", hint: "ThreadList.Toolbar.startNewChat")
                .foregroundStyle(Color.App.white, Color.App.primary)
        }

        if EnvironmentValues.isTalkTest {
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
                ToolbarButtonItem(imageName: "line.3.horizontal.decrease.circle", hint: "ThreadList.Toolbar.filter")
            }
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
