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
    var thread: Conversation
    @EnvironmentObject var viewModel: ThreadsViewModel
    var canAddParticipant: Bool { thread.group ?? false && thread.admin ?? false == true }

    var body: some View {
        Button {
            viewModel.togglePin(thread)
        } label: {
            Label((thread.pin ?? false) ? "Thread.unpin" : "Thread.pin", systemImage: "pin")
        }

        Button {
            viewModel.clearHistory(thread)
        } label: {
            Label("Thread.clearHistory", systemImage: "clock")
        }

        Button {
            viewModel.toggleMute(thread)
        } label: {
            Label((thread.mute ?? false) ? "Thread.unmute" : "Thread.mute", systemImage: "speaker.slash")
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

        Button(role: .destructive) {
            viewModel.leave(thread)
        } label: {
            Label("Thread.leave", systemImage: "rectangle.portrait.and.arrow.right")
        }

        if thread.admin == true {
            Button(role: .destructive) {
                viewModel.selectedThraed = thread
                viewModel.sheetType = .firstConfrimation
            } label: {
                Label("General.delete", systemImage: "trash")
            }
        }

        Button {
            viewModel.toggleArchive(thread)
        } label: {
            Label(thread.isArchive == false ? "Thread.archive" : "Thread.unarchive", systemImage: thread.isArchive == false ? "tray.and.arrow.down" : "tray.and.arrow.up")
        }

        if canAddParticipant {
            Button {
                viewModel.showAddParticipants(thread)
            } label: {
                Label("Thread.invite", systemImage: "person.crop.circle.badge.plus")
            }
        }

        if thread.isPrivate {
            Button {
                viewModel.makeThreadPublic(thread)
            } label: {
                Label("Thread.switchToPublic", systemImage: "arrow.triangle.swap")
            }
        }
    }
}
