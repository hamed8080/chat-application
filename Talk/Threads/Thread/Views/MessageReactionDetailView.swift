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
    let selectedStickerTabId: String?
    private var messageId: Int { message.id ?? -1 }
    private var conversationId: Int { message.conversation?.id ?? -1 }

    init(message: Message, selectedStickerTabId: String? = nil) {
        self.message = message
        self.selectedStickerTabId = selectedStickerTabId
    }

    var body: some View {
        TabContainerView(
            selectedId: selectedStickerTabId ?? "General.all",
            tabs: tabs,
            config: .init(alignment: .top)
        )
        .background(Color.App.bgPrimary)
        .navigationTitle("Reactions to: \(message.messageTitle.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    var tabs: [TabItem] {
        if summaryTabs.count > 0 {
            var tabs = summaryTabs
            tabs.insert(allTab, at: 0)
            return tabs
        } else {
            return []
        }
    }

    var allTab: TabItem {
        TabItem(
            tabContent: ParticiapntsPageSticker(
                sticker: nil,
                messageId: messageId,
                conversationId: conversationId
            ),
            title: "General.all"
        )
    }

    var summaryTabs: [TabItem] {
        ChatManager.activeInstance?.reaction.inMemoryReaction.summary(for: messageId)
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
    }
}

struct ParticiapntsPageSticker: View {
    let sticker: Sticker?
    @State private var reactions: [Reaction] = []
    private let messageId: Int
    private let conversationId: Int
    @State var viewHasAppeared = false

    init(sticker: Sticker?, reactions: [Reaction] = [], messageId: Int, conversationId: Int) {
        self.sticker = sticker
        self.reactions = reactions
        self.messageId = messageId
        self.conversationId = conversationId
    }

    var body: some View {
        List {
            ForEach(reactions) { reaction in
                ReactionParticipantRow(reaction: reaction, messageId: messageId)
                    .listRowBackground(Color.App.bgPrimary)
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
        .listStyle(.plain)
        .onAppear {
            if !viewHasAppeared {
                viewHasAppeared = true
                ReactionViewModel.shared.getDetail(for: messageId,
                                                   offset: reactions.count,
                                                   conversationId: conversationId,
                                                   sticker: sticker
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reaction)) { newValue in
            guard let event = newValue.object as? ReactionEventTypes,
                  case let .list(resposne) = event,
                  resposne.result?.messageId == messageId,
                  let reactions = resposne.result?.reactions
            else { return }
            let groups = Dictionary(grouping: reactions.compactMap{$0.reaction}, by: {$0})
            if self.sticker == nil {
                reactions.forEach { reaction in
                    if !self.reactions.contains(where: {$0.id == reaction.id}) {
                        self.reactions.append( reaction)
                    }
                }
            } else if groups.count == 1, sticker == groups.first?.value.first {
                reactions.forEach { reaction in
                    if !self.reactions.contains(where: {$0.id == reaction.id}) {
                        self.reactions.append( reaction)
                    }
                }
            }
        }
    }
}

struct ReactionParticipantRow: View {
    let reaction: Reaction
    let messageId: Int

    var body: some View {
        HStack(alignment: .center) {
            ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: reaction.participant?.image, userName: reaction.participant?.name)
                .scaledToFit()
                .id(reaction.participant?.id)
                .font(.iransansBoldCaption2)
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.App.blue.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius:(24)))

            VStack(alignment: .leading, spacing: 4) {
                Text(reaction.participant?.name ?? "")
                    .padding(.leading, 4)
                    .lineLimit(1)
                    .font(.iransansSubtitle)
                if let time = reaction.time {
                    Text(time.date.localFormattedTime ?? "")
                        .padding(.leading, 4)
                        .font(.iransansCaption3)
                        .foregroundColor(Color.App.gray1)
                }
            }
            Spacer()
            Text(verbatim: reaction.reaction?.emoji ?? "")
                .font(.system(size: 18))
                .frame(width: 28, height: 28)
                .background(ChatManager.activeInstance?.reaction.inMemoryReaction.currentReaction(messageId)?.reaction?.emoji == reaction.reaction?.emoji ? Color.App.primary.opacity(0.3) : .clear)
                .clipShape(RoundedRectangle(cornerRadius:(14)))
        }
    }
}

struct MessageReactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessageReactionDetailView(message: Message(id: 1, message: "TEST", conversation: Conversation(id: 1)))

        ReactionParticipantRow(reaction: .init(id: 1, reaction: .like, participant: .init(image: "https://imgv3.fotor.com/images/cover-photo-image/a-beautiful-girl-with-gray-hair-and-lucxy-neckless-generated-by-Fotor-AI.jpg"), time: nil), messageId: 1)
            .frame(width: 300, height: 300)
    }
}
