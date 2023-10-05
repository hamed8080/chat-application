//
//  MessageReactionDetailView.swift
//  Talk
//
//  Created by hamed on 8/13/23.
//

import Chat
import TalkUI
import TalkViewModels
import ChatModels
import SwiftUI
import TalkExtensions

struct MessageReactionDetailView: View {
    let message: Message
    private var messageId: Int { message.id ?? -1 }
    private var conversationId: Int { message.conversation?.id ?? -1 }

    init(message: Message) {
        self.message = message
    }

    var body: some View {
        TabContainerView(
            selectedId: "all",
            tabs: tabItems,
            config: .init(alignment: .top)
        )
        .navigationTitle("Reactions to: \(message.messageTitle.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    var tabItems: [TabItem] {
        var items = ChatManager.activeInstance?.reaction.inMemoryReaction.summary(for: messageId)
            .compactMap { reaction in
                TabItem(
                    tabContent: ParticiapntsPageSticker(
                        sticker: reaction.sticker ?? .unknown,
                        messageId: messageId,
                        conversationId: conversationId
                    ),
                    title: "\(reaction.sticker?.emoji ?? "all") \(reaction.count ?? 0)"
                )
            } ?? []
        if items.count > 0 {
            items.insert(TabItem(
                tabContent: ParticiapntsPageSticker(
                    sticker: .unknown,
                    messageId: messageId,
                    conversationId: conversationId
                ),
                title: "all"
            ), at: 0)
            return items
        } else {
            return []
        }
    }
}

struct ParticiapntsPageSticker: View {
    let sticker: Sticker
    @State private var reactions: [Reaction] = []
    private let messageId: Int
    private let conversationId: Int

    init(sticker: Sticker, reactions: [Reaction] = [], messageId: Int, conversationId: Int) {
        self.sticker = sticker
        self.reactions = reactions
        self.messageId = messageId
        self.conversationId = conversationId
    }

    var body: some View {
        List {
            Color.random
            ForEach(reactions) { reaction in
                HStack {
                    Text(reaction.reaction?.emoji ?? "")
                    ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: reaction.participant?.image, userName: reaction.participant?.name)
                        .id(reaction.participant?.id)
                        .font(.iransansBoldCaption2)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(12)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reaction.participant?.name ?? "")
                            .padding(.leading, 4)
                            .lineLimit(1)
                            .font(.headline)
                        if let time = reaction.time {
                            Text(time.date.timeAgoSinceDateCondense ?? "")
                                .padding(.leading, 4)
                                .font(.iransansCaption3)
                                .foregroundColor(Color.gray)
                        }
                    }
                }
                .onAppear {
                    if reactions.last == reaction {
                        ReactionViewModel.shared.getDetail(for: messageId,
                                                           offset: reactions.count,
                                                           conversationId: conversationId,
                                                           sticker: sticker
                        )
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(width: 0, height: 12)
        }
    }
}

struct MessageReactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessageReactionDetailView(message: Message(id: 1, message: "TEST", conversation: Conversation(id: 1)))
    }
}
