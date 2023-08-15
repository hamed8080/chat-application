//
//  MessageReactionDetailView.swift
//  Talk
//
//  Created by hamed on 8/13/23.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MessageReactionDetailView: View {
    let message: Message
    private var messageId: Int { message.id ?? -1 }
    private var conversationId: Int { message.conversation?.id ?? -1 }
    @Environment(\.dismiss) var dismiss
    @State private var reactionDeatils: ReactionList?
    @State private var reactions: [Reaction] = []

    init(message: Message) {
        self.message = message
    }

    var body: some View {
        List {
            ForEach(reactions) { reaction in
                HStack {
                    Text(Emoji(rawValue: reaction.reaction ?? -1)?.emoji ?? "")
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
                        ReactionViewModel.shared.getDetail(for: messageId, offset: reactions.count, conversationId: conversationId)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        ChatManager.activeInstance?.reaction.delete(.init(reactionId: reaction.id ?? -1, conversationId: conversationId))
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Reactions to: \(message.messageTitle.trimmingCharacters(in: .whitespacesAndNewlines))")
        .onAppear {
            ReactionViewModel.shared.getDetail(for: messageId, conversationId: conversationId)
        }
        .onDisappear {
            ReactionViewModel.shared.selectedMessageReactionDetails = nil
        }
        .onReceive(ReactionViewModel.shared.objectWillChange) { _ in
            if messageId == ReactionViewModel.shared.selectedMessageReactionDetails?.messageId {
                reactionDeatils = ReactionViewModel.shared.selectedMessageReactionDetails
                reactions = reactionDeatils?.reactions ?? []
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
}

struct MessageReactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessageReactionDetailView(message: Message(id: 1, message: "TEST", conversation: Conversation(id: 1)))
    }
}
