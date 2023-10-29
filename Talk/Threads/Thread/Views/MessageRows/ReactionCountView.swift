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

struct ReactionCountView: View {
    let message: Message
    private var messageId: Int { message.id ?? -1 }
    @State var reactionCountList: [ReactionCount] = []
    var inMemoryReaction: InMemoryReactionProtocol? { ChatManager.activeInstance?.reaction.inMemoryReaction }

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                Spacer()
                ForEach(reactionCountList) { reactionCount in
                    ReactionCountRow(messageId: messageId, reactionCount: reactionCount)
                }
                Spacer()
            }
        }
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
    let messageId: Int
    @State var count: Int = 0
    let reactionCount: ReactionCount
    @State var currentUserReaction: Reaction?
    var inMemoryReaction: InMemoryReactionProtocol? { ChatManager.activeInstance?.reaction.inMemoryReaction }

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
                setCurrentUserReaction()
            }
        }
        .onAppear {
            count = reactionCount.count ?? 0
            setCurrentUserReaction()
        }
        .onTapGesture {
            print("tapped on \(reactionCount.sticker?.emoji ?? "") with messageId: \(messageId)")
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
            count = inMemoryReaction?.summary(for: self.messageId)
                .first(where: { $0.sticker == reactionCount.sticker })?.count ?? 0
        }
    }

    func setCurrentUserReaction() {
        if let userReaction = inMemoryReaction?.currentReaction(messageId) {
            currentUserReaction = userReaction
        } else {
            currentUserReaction = nil
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
