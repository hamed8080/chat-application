//
//  BlockedAssistantsView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import Chat
import ChatAppExtensions
import ChatAppUI
import ChatAppViewModels
import ChatCore
import ChatDTO
import ChatModels
import Logger
import SwiftUI

struct BlockedAssistantsView: View {
    @EnvironmentObject var viewModel: AssistantViewModel

    var body: some View {
        List {
            ForEach(viewModel.blockedAssistants) { blockedAssistant in
                AssistantRow(assistant: blockedAssistant)
            }
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .navigationTitle("Blocked Assistants")
        .animation(.easeInOut, value: viewModel.blockedAssistants.count)
        .task {
            viewModel.blockedList()
        }
    }
}

struct BlockedAssistantsView_Previews: PreviewProvider {
    static let participant = MockData.participant(1)
    static var viewModel = AssistantViewModel()
    static let assistant = Assistant(id: 1, participant: participant)

    static var previews: some View {
        BlockedAssistantsView()
            .environmentObject(viewModel)
            .onAppear {
                let response: ChatResponse<[Assistant]> = .init(result: [assistant])
                viewModel.onBlockedListAssistant(response)
            }
    }
}
