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
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @EnvironmentObject var navVM: NavigationModel

    var body: some View {
        List(threadsVM.archives) { thread in
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
        .background(Color.App.bgPrimary)
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $threadsVM.isLoading)
        }
        .animation(.easeInOut, value: threadsVM.filtered.count)
        .animation(.easeInOut, value: threadsVM.isLoading)
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
            container.threadsVM.archived = true
            container.threadsVM.getArchivedThreads()
            container.animateObjectWillChange()
        }
        .onDisappear {
            container.threadsVM.archived = false
            container.animateObjectWillChange()
        }
    }
}

struct ArchivesView_Previews: PreviewProvider {
    static var previews: some View {
        ArchivesView(container: .init(delegate: ChatDelegateImplementation.sharedInstance))
    }
}
