import ChatAppExtensions
import SwiftUI
import ChatModels

extension Conversation {
    public typealias MessageIconStatus = (icon: UIImage, fgColor: Color)
    public func messageStatusIcon(currentUserId: Int?) -> MessageIconStatus? {
        if !isLastMessageMine(currentUserId: currentUserId) { return nil }
        if partnerLastSeenMessageId == lastMessageVO?.id {
            return (Message.seenImage!, .orange)
        } else if partnerLastDeliveredMessageId == lastMessageVO?.id ?? 0 {
            return (Message.seenImage!, .gray.opacity(0.7))
        } else if lastMessageVO?.id ?? 0 > partnerLastSeenMessageId ?? 0 {
            return (Message.sentImage!, .gray.opacity(0.7))
        } else { return nil }
    }
}
