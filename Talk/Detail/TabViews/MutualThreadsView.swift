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
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
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
