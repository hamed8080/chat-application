//
//  ThreadListRowBackground.swift
//  Talk
//
//  Created by hamed on 12/5/23.
//

import SwiftUI
import ChatModels
import TalkViewModels

struct ThreadListRowBackground: View {
    let thread: Conversation
    @EnvironmentObject var navVM: NavigationModel
    var isSelected: Bool { navVM.selectedThreadId == thread.id }

    var body: some View {
        isSelected ? Color.App.primary.opacity(0.5) : thread.pin == true ? Color.App.bgTertiary : Color.App.bgPrimary
    }
}

struct ThreadListRowBackground_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListRowBackground(thread: .init(id: 1))
    }
}