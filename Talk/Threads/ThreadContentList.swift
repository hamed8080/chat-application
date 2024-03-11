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
    private var sheetBinding: Binding<Bool> { Binding(get: { threadsVM.sheetType != nil }, set: { _ in }) }

    var body: some View {
        List {
            ForEach(threadsVM.threads) { thread in
                ThreadRow(thread: thread) {
                    AppState.shared.objectsContainer.navVM.switchFromThreadList(thread: thread)
                }
                .listRowInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 8))
                .listRowSeparatorTint(Color.App.dividerSecondary)
                .listRowBackground(ThreadListRowBackground(thread: thread))
                .onAppear {
                    if self.threadsVM.threads.last == thread {
                        threadsVM.loadMore()
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
        .animation(.easeInOut, value: threadsVM.threads.count)
        .animation(.easeInOut, value: threadsVM.isLoading)
        .overlay(ThreadListShimmer().environmentObject(threadsVM.shimmerViewModel))
        .safeAreaInset(edge: .top, spacing: 0) {
            ConversationTopSafeAreaInset(container: container)
        }
        .overlay(alignment: .bottom) {
            /// The if below is for shimmer
            if threadsVM.firstSuccessResponse {
                ListLoadingView(isLoading: $threadsVM.isLoading)
            }
        }
        .sheet(isPresented: sheetBinding) {
            ThreadsSheetFactoryView()
        }
        .refreshable {
            threadsVM.refresh()            
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
                .task {
                    await container.threadsVM.appendThreads(threads: MockData.generateThreads(count: 5))
                    if let fileURL = Bundle.main.url(forResource: "new_message", withExtension: "mp3") {
                        try? container.audioPlayerVM.setup(fileURL: fileURL, ext: "mp3", title: "Note")
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
                    try? audioPlayerVm.setup(fileURL: URL(string: "https://www.google.com")!, ext: "mp3", title: "Note", subtitle: "Test")
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
