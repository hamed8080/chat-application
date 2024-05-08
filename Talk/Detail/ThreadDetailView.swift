//
//  DetailView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct ThreadDetailView: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) private var dismiss    

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    DetailSectionContainer()
                    DetailTabContainer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.App.bgPrimary)
        .environmentObject(viewModel)
        .safeAreaInset(edge: .top, spacing: 0) { DetailToolbarContainer() }
        .background(DetailAddOrEditContactSheetView())
        .onReceive(viewModel.$dismiss) { newValue in
            if newValue {
                prepareToDismiss()
            }
        }
        .onAppear {
            setupPreviousDetailViewModel()
        }
    }

    private func prepareToDismiss() {
        AppState.shared.objectsContainer.navVM.remove()
        AppState.shared.objectsContainer.threadDetailVM.clear()
        dismiss()
    }

/*
 We must do this because we use a shared detail view model.
 It will lead to problems if we don't do this when going deeply through threads.
 It will refresh the whole detail in the previous thread but will do the job.
*/
    private func setupPreviousDetailViewModel() {
        let threadVM = AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.viewModel
        if viewModel.thread?.id ?? 0 != threadVM?.threadId, let threadVM = threadVM {
            viewModel.setup(thread: threadVM.thread, threadVM: threadVM)
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadDetailView()
            .environmentObject(ThreadDetailViewModel())
    }
}
