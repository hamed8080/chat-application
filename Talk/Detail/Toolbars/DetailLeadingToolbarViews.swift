//
//  DetailLeadingToolbarViews.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailLeadingToolbarViews: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    
    var body: some View {
        NavigationBackButton {
            Task {
                await viewModel.threadVM?.scrollVM.disableExcessiveLoading()
                AppState.shared.objectsContainer.contactsVM.editContact = nil
                AppState.shared.objectsContainer.navVM.remove()
                AppState.shared.objectsContainer.threadDetailVM.clear()
            }
        }
    }
}

struct DetailLeadingToolbarViews_Previews: PreviewProvider {
    static var previews: some View {
        DetailLeadingToolbarViews()
    }
}
