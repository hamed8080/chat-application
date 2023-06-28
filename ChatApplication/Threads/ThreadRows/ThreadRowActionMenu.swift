//
//  ThreadRowActionMenu.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import ChatAppViewModels
import ChatModels
import Foundation
import SwiftUI

struct ThreadRowActionMenu: View {
    var thread: Conversation
    @EnvironmentObject var viewModel: ThreadsViewModel
    var canAddParticipant: Bool { thread.group ?? false && thread.admin ?? false == true }

    var body: some View {
        Button {
            viewModel.togglePin(thread)
        } label: {
            Label((thread.pin ?? false) ? "UnPin" : "Pin", systemImage: "pin")
        }

        Button {
            viewModel.clearHistory(thread)
        } label: {
            Label("Clear History", systemImage: "clock")
        }

        Button {
            viewModel.toggleMute(thread)
        } label: {
            Label((thread.mute ?? false) ? "Unmute" : "Mute", systemImage: "speaker.slash")
        }

        Button {
            viewModel.showAddThreadToTag(thread)
        } label: {
            Label("Add To Folder", systemImage: "folder.badge.plus")
        }

        Button {
            viewModel.spamPV(thread)
        } label: {
            Label("Spam", systemImage: "ladybug")
        }

        Button(role: .destructive) {
            viewModel.leave(thread)
        } label: {
            Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
        }

        if thread.admin == true {
            Button(role: .destructive) {
                viewModel.selectedThraed = thread
                viewModel.sheetType = .firstConfrimation
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }

        Button {
            viewModel.toggleArchive(thread)
        } label: {
            Label(thread.isArchive == false ? "Archive" : "Unarchive", systemImage: thread.isArchive == false ? "tray.and.arrow.down" : "tray.and.arrow.up")
        }

        if canAddParticipant {
            Button {
                viewModel.showAddParticipants(thread)
            } label: {
                Label("Invite", systemImage: "person.crop.circle.badge.plus")
            }
        }

        if thread.isPrivate {
            Button {
                viewModel.makeThreadPublic(thread)
            } label: {
                Label("Switch to public thread", systemImage: "arrow.triangle.swap")
            }
        }
    }
}
