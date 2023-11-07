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
    @State var showCreateConversationSheet = false
    @State var showFastMessageSheet = false
    @State var showJoinSheet = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 32) {
                Button {
                    showCreateConversationSheet.toggle()
                } label: {
                    Label("ThreadList.Toolbar.startNewChat", systemImage: "bubble.left.and.bubble.right.fill")
                }

                Button {
                    showFastMessageSheet.toggle()
                } label: {
                    Label("ThreadList.Toolbar.joinToPublicThread", systemImage: "door.right.hand.open")
                }

                Button {
                    showJoinSheet.toggle()
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
        .sheet(isPresented: $showCreateConversationSheet) {
            StartThreadContactPickerView()
        }
        .sheet(isPresented: $showFastMessageSheet) {
            CreateDirectThreadView { invitee, message in
                threadsVM.fastMessage(invitee, message)
            }
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinToPublicThreadView { publicThreadName in
                threadsVM.joinToPublicThread(publicThreadName)
            }
        }
    }

    private var isLargeSize: Bool {
        let mode = UIApplication.shared.windowMode()
        if mode == .ipadFullScreen || mode == .ipadHalfSplitView || mode == .ipadTwoThirdSplitView {
            return true
        } else {
            return false
        }
    }

    struct CreateConversationPicker_Previews: PreviewProvider {
        static var previews: some View {
            CreateConversationPicker()
        }
    }
}
