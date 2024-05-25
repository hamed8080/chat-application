//
//  ThreadLeadingToolbar.swift
//  Talk
//
//  Created by hamed on 10/23/23.
//

import SwiftUI
import TalkViewModels
import ChatModels

struct ThreadLeadingToolbar: View {
    private var thread: Conversation { viewModel.thread }
    let viewModel: ThreadViewModel
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad && sizeClass != .compact {
            ToolbarButtonItem(imageName: "sidebar.leading") {
                AppState.isInSlimMode = UIApplication.shared.windowMode().isInSlimMode
                NotificationCenter.closeSideBar.post(name: Notification.Name.closeSideBar, object: nil)
            }
            .offset(y: -1.5)
            .foregroundStyle(Color.App.toolbarButton)
        }

        NavigationBackButton(automaticDismiss: false) {
            AppState.shared.appStateNavigationModel = .init()
            AppState.shared.objectsContainer.navVM.remove(threadId: viewModel.thread.id)
        }
    }
}
