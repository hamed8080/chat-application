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
    }

    private func prepareToDismiss() {
        AppState.shared.objectsContainer.navVM.remove()
        AppState.shared.objectsContainer.threadDetailVM.clear()
        dismiss()
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadDetailView()
            .environmentObject(ThreadDetailViewModel())
    }
}
