//
//  ThreadMainToolbar.swift
//  Talk
//
//  Created by hamed on 12/9/23.
//

import Foundation
import SwiftUI
import TalkViewModels

//struct ThreadMainToolbar: View {
//    let viewModel: ThreadViewModel
//
//    var body: some View {
//        ToolbarView(
//            searchId: "\(viewModel.threadId)",
//            title: nil,
//            showSearchButton: false,
//            searchPlaceholder: "General.searchHere",
//            leadingViews: ThreadLeadingToolbar(viewModel: viewModel),
//            centerViews:  ThreadViewCenterToolbar(threadId: viewModel.threadId),
//            trailingViews: ThreadViewTrailingToolbar()
//        ) { searchValue in
//            viewModel.searchedMessagesViewModel.searchText = searchValue
//        }
//        .environmentObject(viewModel)
//    }
//}
