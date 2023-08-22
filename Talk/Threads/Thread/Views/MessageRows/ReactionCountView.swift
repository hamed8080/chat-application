//
//  ReactionCountView.swift
//  Talk
//
//  Created by hamed on 8/22/23.
//

import ChatAppExtensions
import ChatModels
import SwiftUI

struct ReactionCountView: View {
    let reactionCountList: ReactionCountList

    var body: some View {
        if let messageId = reactionCountList.messageId, let reactionCounts = reactionCountList.reactionCounts, reactionCounts.count > 0 {
            ScrollView(.horizontal) {
                HStack {
                    Spacer()
                    ForEach(reactionCounts) { reactionCount in
                        ReactionCountRow(messageId: messageId, reactionCount: reactionCount)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct ReactionCountRow: View {
    let messageId: Int
    let reactionCount: ReactionCount

    var body: some View {
        HStack {
            if let sticker = reactionCount.sticker, let sticker = Emoji(rawValue: sticker) {
                Text(verbatim: sticker.emoji)
                    .frame(width: 20, height: 20)
                    .font(.system(size: 14))
            }
            if let count = reactionCount.count {
                Text("\(count)")
                    .font(.iransansBody)
            }
        }
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 6)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .onTapGesture {
            print("tapped on \(Emoji(rawValue: reactionCount.sticker ?? 1)?.emoji ?? "") with messageId: \(messageId)")
        }
    }
}

struct ReactionCountView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionCountView(reactionCountList: .init(messageId: 1, reactionCounts: [
            .init(sticker: 1, count: 10),
            .init(sticker: 2, count: 40),
            .init(sticker: 3, count: 2),
            .init(sticker: 4, count: 5),
        ]))
    }
}
