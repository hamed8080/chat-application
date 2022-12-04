//
//  CallParticipantsContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct CallParticipantsContentList: View {
    @EnvironmentObject
    var viewModel: CallParticipantsViewModel

    var body: some View {
        List {
            ForEach(viewModel.callParticipants, id: \.id) { participant in
                CallParticipantRow(participant: participant)
            }
            .listRowBackground(Color.clear)
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .listStyle(PlainListStyle())
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(.all)
        )
        .onAppear {
            viewModel.getParticipantsIfConnected()
        }
    }
}

struct CallParticipantContentList_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CallParticipantsViewModel(callId: 1)
        CallParticipantsContentList()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.callParticipants = MockData.generateCallParticipant(count: 5)
                viewModel.objectWillChange.send()
            }
    }
}
