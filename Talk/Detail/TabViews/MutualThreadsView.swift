//
//  MutualThreadsView.swift
//  Talk
//
//  Created by hamed on 3/26/23.
//

import SwiftUI
import TalkViewModels

struct MutualThreadsView: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        if !viewModel.mutualThreads.isEmpty {
            ForEach(viewModel.mutualThreads) { thread in
                SelectThreadRow(thread: thread)
                    .padding([.leading, .top, .bottom], 8)
            }
        }
    }
}

struct MutualThreadsView_Previews: PreviewProvider {
    static var previews: some View {
        MutualThreadsView()
    }
}
