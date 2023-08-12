//
//  ReactionMenuView.swift
//  Talk
//
//  Created by hamed on 8/12/23.
//

import ChatAppViewModels
import ChatModels
import SwiftUI

struct ReactionMenuView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private let emojis = ["😂", "🤣", "❤️", "😍", "☹️"]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    viewModel.reaction(emoji)
                } label: {
                    Text(verbatim: emoji)
                        .frame(width: 48, height: 48)
                        .font(.system(size: 48))
                }
            }
        }
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(16)
    }
}

struct ReactionMenuView_Previews: PreviewProvider {
    struct Preview: View {
        let message = Message(id: 1, message: "TEST", messageType: .text)

        var body: some View {
            ReactionMenuView()
                .environmentObject(MessageRowViewModel(message: message, viewModel: ThreadViewModel(thread: Conversation(id: 1))))
        }
    }

    static var previews: some View {
        Preview()
    }
}
