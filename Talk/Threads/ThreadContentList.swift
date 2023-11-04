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
            let isSelected = container.navVM.selectedThreadId == thread.id
            Button {
                navVM.append(thread: thread)
            } label: {
                ThreadRow(isSelected: isSelected, thread: thread)
                    .onAppear {
                        if self.threadsVM.filtered.last == thread {
                            threadsVM.loadMore()
                        }
                    }
            }
            .listRowInsets(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
            .listRowSeparatorTint(Color.App.separator)
            .listRowBackground(isSelected ? Color.App.primary.opacity(0.5) : thread.pin == true ? Color.App.bgTertiary : Color.App.bgPrimary)
        }
        .safeAreaInset(edge: .top) {
            if UIApplication.shared.isInSlimMode {
                AudioPlayerView()
            }
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
            container.contactsVM.closeBuilder()
        } content: {
            ThreadsSheetFactoryView()
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
        ToolbarButtonItem(imageName: "plus.circle.fill", hint: "ThreadList.Toolbar.startNewChat") {
            threadsVM.sheetType = .createConversation
        }
        .foregroundStyle(Color.App.white, Color.App.primary)
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
    struct AudioPlayerPreview: View {
        @ObservedObject var audioPlayerVm = AVAudioPlayerViewModel()

        var body: some View {
            AudioPlayerView()
                .environmentObject(audioPlayerVm)
                .onAppear {
                    audioPlayerVm.setup(fileURL: URL(string: "https://www.google.com")!, ext: "mp3", title: "Note", subtitle: "Test")
                    audioPlayerVm.isClosed = false
                }
        }
    }

    static var previews: some View {
        AudioPlayerPreview()
            .previewDisplayName("AudioPlayerPreview")
        Preview()
    }
}
