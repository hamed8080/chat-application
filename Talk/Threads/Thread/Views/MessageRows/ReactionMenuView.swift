//
//  ReactionMenuView.swift
//  Talk
//
//  Created by hamed on 8/12/23.
//

import ChatAppViewModels
import ChatModels
import SwiftUI

enum Emoji: Int, CaseIterable, Identifiable {
    var id: Self { self }
    case hifive = 1
    case like = 2
    case happy = 3
    case cry = 4

    var string: String {
        switch self {
        case .hifive:
            return "hifive"
        case .like:
            return "like"
        case .happy:
            return "happy"
        case .cry:
            return "cry"
        }
    }

    var emoji: String {
        switch self {
        case .hifive:
            return "👋"
        case .like:
            return "❤️"
        case .happy:
            return "😂"
        case .cry:
            return "😭"
        }
    }
}

struct ReactionMenuView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    var currentSelectedReaction: Reaction? { ReactionViewModel.shared.userSelectedReactions.first(where: { $0.key == viewModel.message.id })?.value }
    @State var show = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(Emoji.allCases, id: \.self) { emoji in
                    let isFirst = emoji == Emoji.allCases.first
                    let isLast = emoji == Emoji.allCases.last
                    Button {
                        if let messageId = viewModel.message.id, let conversationId = viewModel.threadVM?.threadId {
                            ReactionViewModel.shared.reaction(emoji.rawValue, messageId: messageId, conversationId: conversationId)
                        }
                    } label: {
                        Text(verbatim: emoji.emoji)
                            .frame(width: 36, height: 36)
                            .font(.system(size: 36))
                            .background(currentSelectedReaction?.reaction == emoji.rawValue ? Color.blue : Color.clear)
                            .cornerRadius(currentSelectedReaction?.reaction == emoji.rawValue ? 4 : 0)
                    }
                    .padding([isFirst ? .leading : isLast ? .trailing : .all], isFirst || isLast ? 16 : 0)
                    .scaleEffect(x: show ? 1.0 : 0.001, y: show ? 1.0 : 0.001, anchor: .center)
                    .transition(.scale)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.55, blendDuration: 0.5)) {
                                show = true
                            }
                        }
                    }
                }
            }
        }
        .fixedSize()
        .padding([.top, .bottom])
        .background(.ultraThickMaterial)
        .cornerRadius(36)
        .overlay {
            RoundedRectangle(cornerRadius: 36)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                .shadow(color: .gray.opacity(0.5), radius: 4, x: 0, y: 0)
        }
    }
}

struct ReactionMenuView_Previews: PreviewProvider {
    struct Preview: View {
        static let message = Message(id: 1, message: "TEST", messageType: .text)
        @StateObject var viewModel = MessageRowViewModel(message: Preview.message, viewModel: ThreadViewModel(thread: Conversation(id: 1)))
        var body: some View {
            ReactionMenuView()
                .environmentObject(viewModel)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                        viewModel.showReactionsOverlay = true
                        viewModel.animateObjectWillChange()
                    }
                }
        }
    }

    static var previews: some View {
        Preview()
    }
}
