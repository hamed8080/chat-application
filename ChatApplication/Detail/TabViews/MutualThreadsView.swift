//
//  MutualThreadsView.swift
//  ChatApplication
//
//  Created by hamed on 3/26/23.
//

import ChatAppViewModels
import SwiftUI

struct MutualThreadsView: View {
    @EnvironmentObject var viewModel: DetailViewModel

    var body: some View {
        if !viewModel.mutualThreads.isEmpty {
            ForEach(viewModel.mutualThreads) { thread in
                SelectThreadRow(thread: thread)
            }
        }
    }
}

struct MutualThreadsView_Previews: PreviewProvider {
    static var previews: some View {
        MutualThreadsView()
    }
}
