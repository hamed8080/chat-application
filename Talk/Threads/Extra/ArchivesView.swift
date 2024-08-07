//
//  ArchivesView.swift
//  Talk
//
//  Created by hamed on 10/29/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct ArchivesView: View {
    let container: ObjectsContainer
    @EnvironmentObject var viewModel: ArchiveThreadsViewModel

    var body: some View {
        List(viewModel.archives) { thread in
            let isSelected = container.navVM.selectedId == thread.id
            ThreadRow(thread: thread) {
                AppState.shared.objectsContainer.navVM.append(thread: thread)
            }
            .listRowInsets(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
            .listRowSeparatorTint(Color.App.dividerSecondary)
            .listRowBackground(isSelected ? Color.App.accent.opacity(0.5) : thread.pin == true ? Color.App.textSecondary : Color.App.accent)
            .onAppear {
                if self.viewModel.archives.last == thread {
                    viewModel.loadMore()
                }
            }
        }
        .background(Color.App.accent)
        .listEmptyBackgroundColor(show: viewModel.archives.isEmpty)
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .animation(.easeInOut, value: viewModel.archives.count)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .normalToolbarView(title: "Tab.archives", type: ArchivesNavigationValue.self)       
        .task {
            viewModel.getArchivedThreads()
        }
    }
}

struct ArchivesView_Previews: PreviewProvider {
    static var previews: some View {
        ArchivesView(container: .init(delegate: ChatDelegateImplementation.sharedInstance))
    }
}
