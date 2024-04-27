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
import TalkModels

struct ConversationPlusContextMenu: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @State var showCreateConversationSheet = false
    @State var showFastMessageSheet = false
    @State var showJoinSheet = false
    @State var showToken: Bool = false
    @EnvironmentObject var builderVM: ConversationBuilderViewModel
    @EnvironmentObject var appstate: AppState

    var body: some View {
        HStack(spacing: 6) {
//            ToolbarButtonItem(imageName: "plus", hint: "ThreadList.Toolbar.startNewChat", padding: 12) {
//                withAnimation {
//                    AppState.shared.objectsContainer.searchVM.searchText = ""
//                    AppState.shared.objectsContainer.contactsVM.searchContactString = ""
//                    NotificationCenter.cancelSearch.post(name: .cancelSearch, object: true)
//                    showCreateConversationSheet.toggle()
//                }
//            }
//            .frame(minWidth: 0, maxWidth: ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: 38)
//            .clipped()
//            .foregroundStyle(Color.App.toolbarButton)
            let image = Language.isRTL ? "talk_logo_text" : "talk_logo_text_en"
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(height: 12)
                .foregroundStyle(Color.App.toolbarButton)
            ConnectionStatusToolbar()
        }
        .padding(.horizontal, 8)
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
        //                .foregroundStyle(Color.App.white, Color.App.accent)
        //        }
        //        .sheet(isPresented: $showToken) {
        //            ManuallyConnectionManagerView()
        //        }
        .sheet(isPresented: $showCreateConversationSheet, onDismiss: onDismissBuilder) {
            StartThreadContactPickerView()
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

    private func onDismissBuilder() {
        builderVM.clear()
    }
}

struct ConversationPlusContextMenu_Previews: PreviewProvider {
    static var previews: some View {
        ConversationPlusContextMenu()
            .environmentObject(ThreadsViewModel())
            .environmentObject(ContactsViewModel())
    }
}
