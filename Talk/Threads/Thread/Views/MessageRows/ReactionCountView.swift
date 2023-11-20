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
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.reactionCountList) { reactionCount in
                    ReactionCountRow(reactionCount: reactionCount)
                }
            }
        }
        .frame(maxWidth: viewModel.maxAllowedWidth)
        .fixedSize(horizontal: true, vertical: false)
        .animation(.easeInOut, value: viewModel.reactionCountList.count)
        .padding(.horizontal, 6)
    }
}

struct ReactionCountRow: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    let reactionCount: ReactionCount

    var body: some View {
        HStack {
            if reactionCount.count ?? -1 > 0 {
                if let sticker = reactionCount.sticker {
                    Text(verbatim: sticker.emoji)
                        .frame(width: 20, height: 20)
                        .font(.system(size: 14))
                }

                Text(reactionCount.count?.localNumber(locale: Language.preferredLocale) ?? "")
                    .font(.iransansBody)
                    .foregroundStyle(isMyReaction ? Color.App.white : Color.App.hint)
            }
        }
        .animation(.easeInOut, value: reactionCount.count ?? -1)
        .padding(EdgeInsets(top: reactionCount.count ?? -1 > 0 ? 6 : 0, leading: reactionCount.count ?? -1 > 0 ? 8 : 0, bottom: reactionCount.count ?? -1 > 0 ? 6 : 0, trailing: reactionCount.count ?? -1 > 0 ? 8 : 0))
        .background(
            Rectangle()
                .fill(isMyReaction ? Color.App.blue.opacity(0.7) : Color.App.primary.opacity(0.1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture {
            if let conversationId = viewModel.message.threadId ?? viewModel.message.conversation?.id, let tappedStciker = reactionCount.sticker {
                AppState.shared.objectsContainer.reactions.reaction(tappedStciker, messageId: viewModel.message.id ?? -1, conversationId: conversationId)
            }
        }
        .customContextMenu(self: self.environmentObject(viewModel)) {
            let selectedEmojiTabId = "\(reactionCount.sticker?.emoji ?? "all") \(reactionCount.count ?? 0)"
            MessageReactionDetailView(message: viewModel.message, selectedStickerTabId: selectedEmojiTabId)
                .frame(width: 300, height: 400)
                .clipShape(RoundedRectangle(cornerRadius:(12)))
        }
    }

    var isMyReaction: Bool {
        viewModel.currentUserReaction?.reaction?.rawValue == reactionCount.sticker?.rawValue
    }
}

struct ReactionCountView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionCountView(viewModel: .init())
    }
}
