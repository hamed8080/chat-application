//
//  ReactionCountView.swift
//  Talk
//
//  Created by hamed on 8/22/23.
//

import TalkExtensions
import TalkViewModels
import ChatModels
import SwiftUI
import Chat
import TalkUI
import TalkModels

struct ReactionCountView: View {
    @EnvironmentObject var viewModel: MessageReactionsViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.reactionCountList) { reactionCount in
                    ReactionCountRow(viewModel: viewModel, reactionCount: reactionCount)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .animation(.easeInOut, value: viewModel.reactionCountList.count)
        .padding(.horizontal, 6)
        .padding(.top, viewModel.topPadding) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
    }
}

struct ReactionCountRow: View {
    let viewModel: MessageReactionsViewModel
    let reactionCount: ReactionCount
    @State var isMyReaction: Bool = false

    var body: some View {
        HStack {
            if reactionCount.count ?? -1 > 0 {
                if let sticker = reactionCount.sticker {
                    Text(verbatim: sticker.emoji)
                        .frame(width: 20, height: 20)
                        .font(.system(size: 14))
                }
                AsyncReactionCountTextView(reactionCount: reactionCount, isMyReaction: isMyReaction)
            }
        }
        .animation(.easeInOut, value: reactionCount.count ?? -1)
        .padding(EdgeInsets(top: reactionCount.count ?? -1 > 0 ? 6 : 0, leading: reactionCount.count ?? -1 > 0 ? 8 : 0, bottom: reactionCount.count ?? -1 > 0 ? 6 : 0, trailing: reactionCount.count ?? -1 > 0 ? 8 : 0))
        .background(
            Rectangle()
                .fill(isMyReaction ? Color.App.color1.opacity(0.9) : Color.App.accent.opacity(0.1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture {
            if let message = viewModel.message, let conversationId = message.threadId ?? message.conversation?.id, let tappedStciker = reactionCount.sticker {
                AppState.shared.objectsContainer.reactions.reaction(tappedStciker, messageId: message.id ?? -1, conversationId: conversationId)
            }
        }
        .customContextMenu(id: reactionCount.id, self: self.environmentObject(viewModel)) {
            let selectedEmojiTabId = "\(reactionCount.sticker?.emoji ?? "all") \(reactionCount.count ?? 0)"
            if let message = viewModel.message {
                MessageReactionDetailView(message: message, selectedStickerTabId: selectedEmojiTabId)
                    .frame(width: 300, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius:(12)))
            }
        }
        .task {
            if viewModel.currentUserReaction?.reaction?.rawValue == reactionCount.sticker?.rawValue {
                isMyReaction = true
            }
        }
    }
}

struct AsyncReactionCountTextView: View {
    let reactionCount: ReactionCount
    @State private var countText = ""
    let isMyReaction: Bool

    var body: some View {
        Text(countText)
            .font(.iransansBody)
            .foregroundStyle(isMyReaction ? Color.App.white : Color.App.textPrimary)
            .task {
                Task {
                    let countText = reactionCount.count?.localNumber(locale: Language.preferredLocale) ?? ""
                    await MainActor.run {
                        self.countText = countText
                    }
                }
            }
    }
}

struct ReactionCountView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionCountView(viewModel: .init())
    }
}
