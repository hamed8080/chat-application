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

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(Emoji.allCases, id: \.self) { emoji in
                    Button {
                        viewModel.reaction(emoji.rawValue)
                    } label: {
                        let isFirst = emoji == Emoji.allCases.first
                        let isLast = emoji == Emoji.allCases.last
                        Text(verbatim: emoji.emoji)
                            .frame(width: 36, height: 36)
                            .font(.system(size: 36))
                            .padding([isFirst ? .leading : isLast ? .trailing : .all], isFirst || isLast ? 16 : 0)
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
