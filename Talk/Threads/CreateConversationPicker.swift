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
    @EnvironmentObject var contactsVM: ContactsViewModel
    @State var showCreateConversationSheet = false
    @State var showFastMessageSheet = false
    @State var showJoinSheet = false

    var body: some View {
        Menu {
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
        } label: {
            ToolbarButtonItem(imageName: "plus.circle.fill", hint: "ThreadList.Toolbar.startNewChat")
                .foregroundStyle(Color.App.white, Color.App.primary)
        }
        .sheet(isPresented: $showCreateConversationSheet) {
            contactsVM.showConversaitonBuilder = false
            contactsVM.closeBuilder()
        } content: {
            StartThreadContactPickerView()
        }
        .onReceive(contactsVM.objectWillChange) {
            /// To remove view if successfully create a conversation group/channel.
            if contactsVM.showConversaitonBuilder == false && showCreateConversationSheet == true {
                withAnimation {
                    showCreateConversationSheet = false
                }
            }
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
