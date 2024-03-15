//
//  MessageReactionsViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Foundation
import TalkModels
import ChatModels
import Chat

public actor ReactionActor {
    weak var viewModel: MessageRowViewModel?
    var inMemoryReaction: InMemoryReactionProtocol? { ChatManager.activeInstance?.reaction.inMemoryReaction }

    public init(viewModel: MessageRowViewModel?) {
        self.viewModel = viewModel
    }
}

public final class MessageReactionsViewModel: ObservableObject {
    public var message: Message? { viewModel?.message }
    public var reactionCountList: ContiguousArray<ReactionCount> = []
    public var currentUserReaction: Reaction?
    public var reactionActor: ReactionActor?
    public var topPadding: CGFloat = 0
    public weak var viewModel: MessageRowViewModel? {
        didSet {
            reactionActor = .init(viewModel: viewModel)
        }
    }

    public func updateWithDelay() {
        Task(priority: .background) {
            await setReactionList()
        }
    }

    func setReactionList() async {
        if let reactionCountList = await reactionActor?.inMemoryReaction?.summary(for: message?.id ?? -1) {
            let reactionCountList = ContiguousArray<ReactionCount>(reactionCountList)
            let currentUserReaction = ChatManager.activeInstance?.reaction.inMemoryReaction.currentReaction(message?.id ?? -1)
            await MainActor.run {
                self.reactionCountList = reactionCountList
                self.currentUserReaction = currentUserReaction
                self.topPadding = reactionCountList.count > 0 ? 10 : 0
                self.animateObjectWillChange()
            }
        }
    }
}
