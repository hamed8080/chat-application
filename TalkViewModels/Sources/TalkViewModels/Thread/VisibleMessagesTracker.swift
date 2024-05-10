//
//  VisibleMessagesTracker
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatModels

protocol StabledVisibleMessageDelegate: AnyObject {
    func onStableVisibleMessages(_ messages: [Message])
}

class VisibleMessagesTracker {
    public private(set) var visibleMessages: [Message] = []
    private var onVisibleMessagesTask: Task <Void, Error>?
    public weak var delegate: StabledVisibleMessageDelegate?

    func append(message: Message) {
        visibleMessages.append(message)
        stableScrolledVisibleMessages()
    }
    
    func remove(message: Message) {
        visibleMessages.removeAll(where: {$0.id == message.id})
    }

    private func stableScrolledVisibleMessages() {
        onVisibleMessagesTask?.cancel()
        onVisibleMessagesTask = nil
        onVisibleMessagesTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    delegate?.onStableVisibleMessages(visibleMessages)
                }
            }
        }
    }
}
