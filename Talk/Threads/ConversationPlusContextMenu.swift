//
//  ConversationPlusContextMenu.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import ChatModels
import TalkUI
import Chat

struct ConversationPlusContextMenu: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @EnvironmentObject var contactsVM: ContactsViewModel
    @State var showCreateConversationSheet = false
    @State var showFastMessageSheet = false
    @State var showJoinSheet = false
    @State var showToken: Bool = false

    var body: some View {
        ToolbarButtonItem(imageName: "plus.circle.fill", hint: "ThreadList.Toolbar.startNewChat", padding: 8) {
            withAnimation {
                showCreateConversationSheet.toggle()
            }
        }
        .frame(minWidth: 0, maxWidth: ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: 38)
        .clipped()
        .foregroundStyle(Color.App.white, Color.App.primary)
//
//        Menu {
//            Button {
//                showCreateConversationSheet.toggle()
//            } label: {
//                Label("ThreadList.Toolbar.startNewChat", systemImage: "bubble.left.and.bubble.right.fill")
//            }
//
//            if EnvironmentValues.isTalkTest {
//                Button {
//                    showToken.toggle()
//                } label : {
//                    Label("Set Token", systemImage: "key.icloud.fill")
//                }
//
//                Button {
//                    showJoinSheet.toggle()
//                } label: {
//                    Label("ThreadList.Toolbar.joinToPublicThread", systemImage: "door.right.hand.open")
//                }
//
//                Button {
//                    showFastMessageSheet.toggle()
//                } label: {
//                    Label("ThreadList.Toolbar.fastMessage", systemImage: "arrow.up.circle.fill")
//                }
//            }
//        } label: {
//            ToolbarButtonItem(imageName: "plus.circle.fill", hint: "ThreadList.Toolbar.startNewChat")
//                .foregroundStyle(Color.App.white, Color.App.primary)
//        }
//        .sheet(isPresented: $showToken) {
//            ManuallyConnectionManagerView()
//        }
        .sheet(isPresented: $showCreateConversationSheet) {
            StartThreadContactPickerView()
        }
        .onReceive(contactsVM.objectWillChange) {
            /// To remove view if successfully create a conversation group/channel.
            if contactsVM.closeConversationContextMenu == true {
                withAnimation {
                    showCreateConversationSheet = false
                    contactsVM.closeConversationContextMenu = false
                }
            }
        }
//        .sheet(isPresented: $showFastMessageSheet) {
//            CreateDirectThreadView { invitee, message in
//                threadsVM.fastMessage(invitee, message)
//            }
//        }
//        .sheet(isPresented: $showJoinSheet) {
//            JoinToPublicThreadView { publicThreadName in
//                threadsVM.joinPublicGroup(publicThreadName)
//            }
//        }
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

struct ConversationPlusContextMenu_Previews: PreviewProvider {
    static var previews: some View {
        ConversationPlusContextMenu()
            .environmentObject(ThreadsViewModel())
            .environmentObject(ContactsViewModel())
    }
}
