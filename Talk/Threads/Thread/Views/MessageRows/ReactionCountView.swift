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
    let message: Message
    private var messageId: Int { message.id ?? -1 }
    @State var reactionCountList: [ReactionCount] = []
    var inMemoryReaction: InMemoryReactionProtocol? { ChatManager.activeInstance?.reaction.inMemoryReaction }
    @State private var contentSize: CGSize = .zero

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(reactionCountList) { reactionCount in
                    ReactionCountRow(message: message, reactionCount: reactionCount)
                }
            }
            .background(
                GeometryReader { geo -> Color in
                    DispatchQueue.main.async {
                        contentSize = geo.size
                    }
                    return Color.clear
                }
            )
        }
        .frame(maxWidth: contentSize.width)
        .frame(height: reactionCountList.count == 0 ? 0 : nil)
        .animation(.easeInOut, value: reactionCountList.count)
        .onReceive(NotificationCenter.default.publisher(for: .reactionMessageUpdated)) { notification in
            if notification.object as? Int == messageId {
                setCountList()
            }
        }
        .onAppear {
            setCountList()
        }
    }

    func setCountList() {
        if let reactionCountList = inMemoryReaction?.summary(for: messageId), reactionCountList != self.reactionCountList {
            self.reactionCountList = reactionCountList
        }
    }
}

struct ReactionCountRow: View {
    let message: Message
    private var messageId: Int { message.id ?? -1 }
    @State var count: Int = 0
    let reactionCount: ReactionCount
    var currentUserReaction: Reaction? { ChatManager.activeInstance?.reaction.inMemoryReaction.currentReaction(messageId) }

    var body: some View {
        HStack {
            if count > 0 {
                if let sticker = reactionCount.sticker {
                    Text(verbatim: sticker.emoji)
                        .frame(width: 20, height: 20)
                        .font(.system(size: 14))
                }

                Text(count.localNumber(locale: Language.preferredLocale) ?? "")
                    .font(.iransansBody)
                    .foregroundStyle(isMyReaction ? Color.App.white : Color.App.hint)
            }
        }
        .animation(.easeInOut, value: count)
        .padding([.leading, .trailing], count > 0 ? 8 : 0)
        .padding([.top, .bottom], count > 0 ? 6 : 0)
        .background(background)
        .cornerRadius(18)
        .onReceive(NotificationCenter.default.publisher(for: .reactionMessageUpdated)) { notification in
            if notification.object as? Int == messageId {
                onNewValue(notification.object as? Int)
            }
        }
        .onAppear {
            count = reactionCount.count ?? 0
        }
        .onTapGesture {
            if let conversationId = message.threadId ?? message.conversation?.id, let tappedStciker = reactionCount.sticker {
                AppState.shared.objectsContainer.reactions.reaction(tappedStciker, messageId: messageId, conversationId: conversationId)
            }
        }
        .onLongPressGesture {
            let selectedEmojiTabId = "\(reactionCount.sticker?.emoji ?? "all") \(reactionCount.count ?? 0)"
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                MessageReactionDetailView(message: message, selectedStickerTabId: selectedEmojiTabId)
                    .frame(width: 300, height: 400)
            )
        }
    }
    var isMyReaction: Bool {
        currentUserReaction?.reaction?.rawValue == reactionCount.sticker?.rawValue
    }

    @ViewBuilder
    var background: some View {
        if isMyReaction {
            Color.App.blue.opacity(0.7).cornerRadius(18)
        } else {
            Rectangle()
                .fill(Color.App.primary.opacity(0.1))
        }
    }

    func onNewValue(_ messageId: Int?) {
        if messageId == self.messageId {
            count = ChatManager.activeInstance?.reaction.inMemoryReaction.summary(for: self.messageId)
                .first(where: { $0.sticker == reactionCount.sticker })?.count ?? 0
        }
    }
}

struct ReactionCountView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionCountView(message: .init(id: 1),
                          reactionCountList: [
                            .init(sticker: .cry, count: 10),
                            .init(sticker: .happy, count: 40),
                            .init(sticker: .hifive, count: 2),
                            .init(sticker: .like, count: 5),
                          ])
    }
}
