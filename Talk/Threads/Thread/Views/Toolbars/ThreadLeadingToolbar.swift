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
            Button {
                NotificationCenter.default.post(name: Notification.Name.closeSideBar, object: nil)
            } label : {
                Image(systemName: "sidebar.leading")
                    .foregroundStyle(Color.main)
            }
        }

        if thread.group == true, thread.type != .channel {
            Image(systemName: "person.2.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.main)
                .frame(width: 16, height: 16)
        }
        if thread.type == .channel {
            Image(systemName: "megaphone.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.main)
                .frame(width: 16, height: 16)
        }
    }
}
