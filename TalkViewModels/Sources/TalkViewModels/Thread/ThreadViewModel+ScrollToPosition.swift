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
    func scrollTo(_ uniqueId: String, _ animation: Animation?, anchor: UnitPoint?)
    func scrollToBottom(animation: Animation?)
    func scrollToLastMessageIfLastMessageIsVisible()
}

extension ThreadViewModel: ScrollToPositionProtocol {

    public func scrollTo(_ uniqueId: String, _ animation: Animation? = .spring(response: 0.05, dampingFraction: 0.8, blendDuration: 0.2), anchor: UnitPoint? = .center) {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
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
            scrollTo(uniqueId, animation)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible() {
        if isAtBottomOfTheList {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.scrollToBottom()
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
