//
//  ThreadEventView.swift
//  ChatApplication
//
//  Created by hamed on 11/30/22.
//

import SwiftUI

struct ThreadEventView: View {
    let threadId: Int
    @StateObject var viewModel = ThreadEventViewModel()

    var body: some View {
        HStack {
            Image(systemName: viewModel.smt?.eventImage ?? "")
                .resizable()
                .foregroundColor(.orange)
                .frame(width: 16, height: 16)

            Text(viewModel.smt?.stringEvent ?? "")
                .lineLimit(1)
                .font(.subheadline.bold())
                .foregroundColor(.orange)
                .onAppear {
                    viewModel.setThread(threadId: threadId)
                }
        }
        .frame(height: viewModel.isShowingEvent ? 16 : 0)
        .animation(.spring(), value: viewModel.isShowingEvent)
    }
}

struct ThreadIsTypingView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadEventView(threadId: MockData.thread.id!)
    }
}
