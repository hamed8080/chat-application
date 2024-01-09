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

struct ThreadRowActionMenu: View {
    var isDetailView: Bool = false
    var thread: Conversation
    @EnvironmentObject var viewModel: ThreadsViewModel
    var canAddParticipant: Bool { thread.group ?? false && thread.admin ?? false == true }

    var body: some View {
        Button {
            viewModel.togglePin(thread)
        } label: {
            Label((thread.pin ?? false) ? "Thread.unpin" : "Thread.pin", systemImage: "pin")
        }

        if thread.type != .selfThread && !isDetailView {
            Button {
                viewModel.toggleMute(thread)
            } label: {
                Label((thread.mute ?? false) ? "Thread.unmute" : "Thread.mute", systemImage: "speaker.slash")
            }
        }

        if EnvironmentValues.isTalkTest {
            Button {
                viewModel.clearHistory(thread)
            } label: {
                Label("Thread.clearHistory", systemImage: "clock")
            }
            
            Button {
                viewModel.showAddThreadToTag(thread)
            } label: {
                Label("Thread.addToFolder", systemImage: "folder.badge.plus")
            }
            
            Button {
                viewModel.spamPV(thread)
            } label: {
                Label("Thread.spam", systemImage: "ladybug")
            }

            Button {
                AppState.shared.objectsContainer.archivesVM.toggleArchive(thread)
            } label: {
                Label(thread.isArchive == true ? "Thread.unarchive" : "Thread.archive" , systemImage: thread.isArchive == true ?  "tray.and.arrow.up" : "tray.and.arrow.down")
            }
            
            if canAddParticipant {
                Button {
                    viewModel.showAddParticipants(thread)
                } label: {
                    Label("Thread.invite", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }

        if thread.group == true {
            let leaveKey = String(localized: .init("Thread.leave"))
            let key = thread.type?.isChannelType == true ? "Thread.channel" : "Thread.group"
            Button(role: .destructive) {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(LeaveThreadDialog(conversation: thread))
            } label: {
                Label(String(format: leaveKey, String(localized: .init(key))), systemImage: "rectangle.portrait.and.arrow.right")
            }
        }

        /// You should be admin or the thread should be a p2p thread with two people.
        if thread.admin == true || thread.group == false {
            let deleteKey = thread.group == false ? "" : String(localized: "Thread.delete")
            let key = thread.type?.isChannelType == true ? "Thread.channel" : thread.group == true ? "Thread.group" : ""
            let groupLocalized = String(format: deleteKey, String(localized: .init(key)))
            let p2pLocalized = String(localized: .init("Genreal.deleteConversation"))
            Button(role: .destructive) {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteThreadDialog(threadId: thread.id))
            } label: {
                Label(thread.group == true ? groupLocalized : p2pLocalized, systemImage: "trash")
            }
        }
    }
}
