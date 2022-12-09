//
//  ThreadIsTypingView.swift
//  ChatApplication
//
//  Created by hamed on 11/30/22.
//

import SwiftUI

struct ThreadIsTypingView: View {
    @ObservedObject var viewModel: ThreadIsTypingViewModel

    init(threadId: Int) {
        viewModel = ThreadIsTypingViewModel(threadId: threadId)
    }

    var body: some View {
        Text("is typing...")
            .lineLimit(1)
            .font(.subheadline.bold())
            .foregroundColor(Color.orange)
            .scaleEffect(x: viewModel.isTyping ? 1 : 0, y: viewModel.isTyping ? 1 : 0)
            .animation(.easeInOut, value: viewModel.isTyping)
    }
}

struct ThreadIsTypingView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadIsTypingView(threadId: MockData.thread.id!)
    }
}
