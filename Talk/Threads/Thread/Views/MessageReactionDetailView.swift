//
//  MessageReactionDetailView.swift
//  Talk
//
//  Created by hamed on 8/13/23.
//

import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MessageReactionDetailView: View {
    let message: Message
    private var messageId: Int { message.id ?? -1 }
    let conversationId: Int
    @Environment(\.dismiss) var dismiss
    @State private var reactionDeatils: ReactionList?

    var body: some View {
        List {
            ForEach(reactionDeatils?.reactions ?? []) { reaction in
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
            }
        }
        .navigationTitle("Reactions to: \(message.messageTitle.trimmingCharacters(in: .whitespacesAndNewlines))")
        .task {
            ReactionViewModel.shared.getDetail(for: messageId, conversationId: conversationId)
        }
        .onReceive(ReactionViewModel.shared.$selectedMessageReactionDetails) { newValue in
            if messageId == newValue?.messageId {
                reactionDeatils = newValue
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
}

struct MessageReactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessageReactionDetailView(message: Message(id: 1, message: "TEST"), conversationId: 1)
    }
}
