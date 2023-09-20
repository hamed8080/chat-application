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

struct ReactionCountView: View {
    let message: Message
    private var messageId: Int { message.id ?? -1 }
    @State var reactionCountList: [ReactionCount] = []
    @State var selectedUserReaction: Reaction?

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                Spacer()
                ForEach(reactionCountList) { reactionCount in
                    ReactionCountRow(messageId: messageId, reactionCount: reactionCount, selectedUserReaction: selectedUserReaction)
                }
                Spacer()
            }
        }
        .animation(.easeInOut, value: reactionCountList.count)
        .onReceive(NotificationCenter.default.publisher(for: .reactionMessageUpdated)) { newValue in
            if newValue.object as? Int == messageId {
                let reactionCountList = ReactionViewModel.shared.reactionCountList.first(where: { $0.messageId == messageId })
                self.reactionCountList = reactionCountList?.reactionCounts ?? []
                selectedUserReaction = reactionCountList?.userReaction
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                if let reactionCountList = ReactionViewModel.shared.reactionCountList.first(where: { $0.messageId == messageId }) {
                    self.reactionCountList = reactionCountList.reactionCounts ?? []
                    selectedUserReaction = reactionCountList.userReaction
                }
            }
        }
    }
}

struct ReactionCountRow: View {
    let messageId: Int
    @State var count: Int = 0
    let reactionCount: ReactionCount
    @State var selectedUserReaction: Reaction?

    var body: some View {
        HStack {
            if count > 0 {
                if let sticker = reactionCount.sticker {
                    Text(verbatim: sticker.emoji)
                        .frame(width: 20, height: 20)
                        .font(.system(size: 14))
                }
                Text("\(count)")
                    .font(.iransansBody)
            }
        }
        .animation(.easeInOut, value: count)
        .padding([.leading, .trailing], count > 0 ? 8 : 0)
        .padding([.top, .bottom], count > 0 ? 6 : 0)
        .background(background)
        .cornerRadius(18)
        .onReceive(NotificationCenter.default.publisher(for: .reactionMessageUpdated)) { newValue in
            onNewValue(newValue.object as? Int)
        }
        .onAppear {
            count = reactionCount.count ?? 0
        }
        .onTapGesture {
            print("tapped on \(reactionCount.sticker?.emoji ?? "") with messageId: \(messageId)")
        }
    }

    @ViewBuilder
    var background: some View {
        if selectedUserReaction?.reaction == reactionCount.sticker {
            Color.blue.opacity(0.8).cornerRadius(18)
        } else {
            Rectangle()
                .background(Material.ultraThinMaterial)
        }
    }

    func onNewValue(_ messageId: Int?) {
        if messageId == self.messageId {
            count = ReactionViewModel.shared.reactionCountList
                .first(where: { $0.messageId == messageId })?
                .reactionCounts?.first(where: { $0.sticker == reactionCount.sticker })?.count ?? 0
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
