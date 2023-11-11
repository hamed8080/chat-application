//
//  ThreadsSheetFactoryView.swift
//  Talk
//
//  Created by hamed on 6/28/23.
//

import Foundation
import SwiftUI
import TalkModels
import TalkViewModels

/// We have to use this due to in the ThreadView we used let viewModel in it will never trigger the sheet.
struct SheetEmptyBackground: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    var sheetBinding: Binding<Bool> { Binding(get: { viewModel.sheetType != nil }, set: { _ in }) }

    var body: some View {
        Color.clear
            .sheet(isPresented: sheetBinding) {
                ThreadSheetView(sheetBinding: sheetBinding)
                    .environmentObject(viewModel.attachmentsViewModel)
            }
    }
}

struct ThreadsSheetFactoryView: View {
    @EnvironmentObject var viewModel: ThreadsViewModel
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        switch viewModel.sheetType {
        case .tagManagement:
            AddThreadToTagsView(viewModel: container.tagsVM) { tag in
                container.tagsVM.addThreadToTag(tag: tag, threadId: viewModel.selectedThraed?.id)
                viewModel.sheetType = nil
            }
        case .firstConfrimation:
            DeleteThreadConfirmationView()
        case .secondConfirmation:
            DeleteThreadConfirmationView()
        case .addParticipant:
            AddParticipantsToThreadView() { contacts in
                viewModel.addParticipantsToThread(contacts)
                viewModel.sheetType = nil
            }      
        case .none:
            Text("Not implemented a sheet type!")
        }
    }
}
