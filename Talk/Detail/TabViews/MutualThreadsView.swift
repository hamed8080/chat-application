//
//  MutualThreadsView.swift
//  Talk
//
//  Created by hamed on 3/26/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct MutualThreadsView: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
        if !viewModel.mutualThreads.isEmpty {
            ForEach(viewModel.mutualThreads) { thread in
                MutualThreadRow(thread: thread)
                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
            }
        }
    }
}

struct MutualThreadsView_Previews: PreviewProvider {
    static var previews: some View {
        MutualThreadsView()
    }
}
