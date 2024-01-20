//
//  ThreadRowActionMenu.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import ChatModels
import Foundation
import SwiftUI
import TalkViewModels
import ActionableContextMenu

struct ThreadRowActionMenu: View {
    @Binding var showPopover: Bool
    var isDetailView: Bool = false
    var thread: Conversation
    @EnvironmentObject var viewModel: ThreadsViewModel
    var canAddParticipant: Bool { thread.group ?? false && thread.admin ?? false == true }

    var body: some View {
        if thread.pin == true || viewModel.serverSortedPinConversations.count < 5 {
            ContextMenuButton(title: (thread.pin ?? false) ? "Thread.unpin" : "Thread.pin", image: "pin") {
                viewModel.togglePin(thread)
                showPopover.toggle()
            }
        }

        if thread.type != .selfThread && !isDetailView {
            ContextMenuButton(title: (thread.mute ?? false) ? "Thread.unmute" : "Thread.mute", image: "speaker.slash") {
                viewModel.toggleMute(thread)
                showPopover.toggle()
            }
        }

        if EnvironmentValues.isTalkTest {
            ContextMenuButton(title: "Thread.clearHistory", image: "clock") {
                viewModel.clearHistory(thread)
                showPopover.toggle()
            }
            
            ContextMenuButton(title: "Thread.addToFolder", image: "folder.badge.plus") {
                viewModel.showAddThreadToTag(thread)
                showPopover.toggle()
            }
            
            ContextMenuButton(title: "Thread.spam", image: "ladybug") {
                viewModel.spamPV(thread)
                showPopover.toggle()
            }

            ContextMenuButton(title: thread.isArchive == true ? "Thread.unarchive" : "Thread.archive", image: thread.isArchive == true ?  "tray.and.arrow.up" : "tray.and.arrow.down") {
                AppState.shared.objectsContainer.archivesVM.toggleArchive(thread)
                showPopover.toggle()
            }
            
            if canAddParticipant {
                ContextMenuButton(title: "Thread.invite", image: "person.crop.circle.badge.plus") {
                    viewModel.showAddParticipants(thread)
                    showPopover.toggle()
                }
            }
        }

        if thread.group == true {
            let leaveKey = String(localized: .init("Thread.leave"))
            let key = thread.type?.isChannelType == true ? "Thread.channel" : "Thread.group"
            ContextMenuButton(title: String(format: leaveKey, String(localized: .init(key))), image: "rectangle.portrait.and.arrow.right", iconColor: Color.App.red) {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(LeaveThreadDialog(conversation: thread))
                showPopover.toggle()
            }
            .foregroundStyle(Color.App.red)
        }

        /// You should be admin or the thread should be a p2p thread with two people.
        if thread.admin == true || thread.group == false {
            let deleteKey = thread.group == false ? "" : String(localized: "Thread.delete")
            let key = thread.type?.isChannelType == true ? "Thread.channel" : thread.group == true ? "Thread.group" : ""
            let groupLocalized = String(format: deleteKey, String(localized: .init(key)))
            let p2pLocalized = String(localized: .init("Genreal.deleteConversation"))
            ContextMenuButton(title: thread.group == true ? groupLocalized : p2pLocalized, image: "trash", iconColor: Color.App.red) {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteThreadDialog(threadId: thread.id))
                showPopover.toggle()
            }
            .foregroundStyle(Color.App.red)
        }
    }
}
