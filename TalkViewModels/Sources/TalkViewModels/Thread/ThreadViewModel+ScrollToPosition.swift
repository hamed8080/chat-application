//
//  ThreadViewModel+ScrollToPosition.swift
//  TalkViewModels
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import ChatModels
import ChatDTO
import ChatCore
import SwiftUI

public protocol ScrollToPositionProtocol {
    var canScrollToBottomOfTheList: Bool { get set }
    func scrollTo(_ uniqueId: String, delay: TimeInterval, _ animation: Animation?, anchor: UnitPoint?)
    func scrollToBottom(animation: Animation?)
    func scrollToLastMessageIfLastMessageIsVisible(_ message: Message)
}

extension ThreadViewModel: ScrollToPositionProtocol {

    public func scrollTo(_ uniqueId: String, delay: TimeInterval = TimeInterval(0.6), _ animation: Animation? = .spring(response: 0.05, dampingFraction: 0.8, blendDuration: 0.2), anchor: UnitPoint? = .center) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            withAnimation(animation) {
                self?.scrollProxy?.scrollTo(uniqueId, anchor: anchor)
            }
        }
    }

    public func setNewOrigin(newOriginY: CGFloat) {
        scrollingUP = lastOrigin > newOriginY
        lastOrigin = newOriginY
        if !isProgramaticallyScroll, scrollingUP, newOriginY < 0, canLoadMoreTop, isFetchedServerFirstResponse {
            moreTop(sections.first?.messages.first?.time?.advanced(by: -1))
        }
    }

    public func scrollToBottom(animation: Animation? = .easeInOut) {
        if let uniqueId = sections.last?.messages.last?.uniqueId {
            scrollTo(uniqueId, delay: .init(0), animation)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible(_ message: Message) {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            withAnimation(.easeInOut.delay(0.1)) {
                scrollProxy?.scrollTo(uniqueId, anchor: .bottom)
            }
        }
    }

    func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true) {
        scrollTo(uniqueId, anchor: .bottom)
        if highlight {
            NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
        }
    }
}
