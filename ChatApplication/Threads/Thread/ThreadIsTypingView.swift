//
//  ThreadIsTypingView.swift
//  ChatApplication
//
//  Created by hamed on 11/30/22.
//

import SwiftUI

struct ThreadIsTypingView: View {
    let threadId: Int
    @StateObject var viewModel = ThreadIsTypingViewModel()

    var body: some View {
        Text("is typing...")
            .lineLimit(1)
            .font(.subheadline.bold())
            .foregroundColor(Color.orange)
            .scaleEffect(x: viewModel.isTyping ? 1 : CGFloat.ulpOfOne, y: viewModel.isTyping ? 1 : CGFloat.ulpOfOne)
            .animation(.easeInOut, value: viewModel.isTyping)
            .onAppear {
                viewModel.setThread(threadId: threadId)
            }
    }
}

struct ThreadIsTypingView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadIsTypingView(threadId: MockData.thread.id!)
    }
}
