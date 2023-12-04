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
    @EnvironmentObject var navVM: NavigationModel

    var body: some View {
        List(viewModel.archives) { thread in
            let isSelected = container.navVM.selectedThreadId == thread.id
            Button {
                navVM.append(thread: thread)
            } label: {
                ThreadRow(isSelected: isSelected, thread: thread)
                    .onAppear {
                        if self.viewModel.archives.last == thread {
                            viewModel.loadMore()
                        }
                    }
            }
            .listRowInsets(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
            .listRowSeparatorTint(Color.App.separator)
            .listRowBackground(isSelected ? Color.App.primary.opacity(0.5) : thread.pin == true ? Color.App.bgTertiary : Color.App.bgPrimary)
        }
        .background(Color.App.bgPrimary)
        .listEmptyBackgroundColor(show: viewModel.archives.isEmpty)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .animation(.easeInOut, value: viewModel.archives.count)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: ArchivesNavigationValue.self)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Tab.archives")
                    .fixedSize()
                    .font(.iransansBoldSubheadline)
            }
        }
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
