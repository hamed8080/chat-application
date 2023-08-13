//
//  OverlayEmojiViews.swift
//  Talk
//
//  Created by hamed on 8/13/23.
//

import ChatAppViewModels
import SwiftUI

struct OverlayEmojiViews: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    @State var show = false

    var body: some View {
        if viewModel.showReactionsOverlay {
            HStack {
                if viewModel.isMe {
                    Spacer()
                }
                ReactionMenuView()
                    .offset(y: -76)
                if !viewModel.isMe {
                    Spacer()
                }
            }
            .transition(
                .move(edge: viewModel.isMe ? .trailing : .leading)
                    .combined(with: .scale(scale: show ? 1.0 : 0.001, anchor: .center))
                    .animation(.spring(response: 0.4, dampingFraction: 0.55, blendDuration: 0.5).speed(0.7))
            )
            .onAppear {
                show = true
            }
            .onDisappear {
                show = false
            }
        }
    }
}

struct OverlayEmojiViews_Previews: PreviewProvider {
    static var previews: some View {
        OverlayEmojiViews()
            .environmentObject(MessageRowViewModel(message: .init(id: 1, message: "TEST"), viewModel: ThreadViewModel(thread: .init(id: 1))))
    }
}
