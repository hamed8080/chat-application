import TalkExtensions
import SwiftUI
import ChatModels

extension Conversation {
    public typealias MessageIconStatus = (icon: UIImage, fgColor: Color)
    public func messageStatusIcon(currentUserId: Int?) -> MessageIconStatus? {
        if group == true || type == .selfThread { return nil }
        if !isLastMessageMine(currentUserId: currentUserId) { return nil }
        let lastID = lastMessageVO?.id ?? 0
        if let partnerLastSeenMessageId = partnerLastSeenMessageId, partnerLastSeenMessageId == lastID {
            return (Message.seenImage!, Color.App.accent)
        } else if let partnerLastDeliveredMessageId = partnerLastDeliveredMessageId, partnerLastDeliveredMessageId == lastID {
            return (Message.sentImage!, Color.App.textSecondary)
        } else if lastID > partnerLastSeenMessageId ?? 0 {
            return (Message.sentImage!, Color.App.textSecondary)
        } else { return nil }
    }
}
