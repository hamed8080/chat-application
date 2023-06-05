//
//  AssistantView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import Chat
import ChatAppViewModels
import Logger
import SwiftUI

struct AssistantView: View {
    @StateObject var viewModel = AssistantViewModel()

    var body: some View {
        List {
            ForEach(viewModel.assistants) { assistant in
                AssistantRow(assistant: assistant)
                    .noSeparators()
                    .id(assistant.participant?.id)
            }
            .onDelete(perform: viewModel.deactive)
            .padding(0)
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .navigationTitle("Assistants")
        .animation(.easeInOut, value: viewModel.assistants.count)
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.deactiveSelectedAssistants()
                } label: {
                    Label {
                        Text("Delete")
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

struct AssistantView_Previews: PreviewProvider {
    static var previews: some View {
        AssistantView()
            .environmentObject(AssistantViewModel())
    }
}
