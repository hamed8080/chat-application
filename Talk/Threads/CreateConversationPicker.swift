//
//  CreateConversationPicker.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import ChatModels
import TalkUI

struct CreateConversationPicker: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 32) {
                Button {
                    threadsVM.sheetType = .showStartConversationBuilder
                } label: {
                    Label("ThreadList.Toolbar.startNewChat", systemImage: "bubble.left.and.bubble.right.fill")
                }

                Button {
                    threadsVM.sheetType = .joinToPublicThread
                } label: {
                    Label("ThreadList.Toolbar.joinToPublicThread", systemImage: "door.right.hand.open")
                }

                Button {
                    threadsVM.sheetType = .fastMessage
                } label: {
                    Label("ThreadList.Toolbar.fastMessage", systemImage: "arrow.up.circle.fill")
                }
            }
            .padding(.leading)
            Spacer()
        }
        .presentationDetents([.fraction((isLargeSize ? 100 : 25) / 100)])
        .presentationBackground(Color.App.bgPrimary)
        .presentationDragIndicator(.visible)
        .foregroundStyle(Color.App.text)
    }

    private var isLargeSize: Bool {
        let mode = UIApplication.shared.windowMode()
        if mode == .ipadFullScreen || mode == .ipadHalfSplitView || mode == .ipadTwoThirdSplitView {
            return true
        } else {
            return false
        }
    }
}
struct CreateConversationPicker_Previews: PreviewProvider {
    static var previews: some View {
        CreateConversationPicker()
    }
}
