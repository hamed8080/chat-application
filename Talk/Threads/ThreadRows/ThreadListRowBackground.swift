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
    @State private var isSelected: Bool = false

    var body: some View {
        color
            .onReceive(AppState.shared.objectsContainer.navVM.objectWillChange) { _ in
                if thread.id == AppState.shared.objectsContainer.navVM.selectedId {
                    isSelected = true
                } else if isSelected {
                    isSelected = false
                }
            }
    }

    var color: Color {
        isSelected ? Color.App.bgChatSelected : thread.pin == true ? Color.App.bgSecondary : Color.App.bgPrimary
    }
}

struct ThreadListRowBackground_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListRowBackground(thread: .init(id: 1))
    }
}
