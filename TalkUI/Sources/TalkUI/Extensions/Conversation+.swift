import TalkExtensions
import SwiftUI
import ChatModels

extension Conversation {
    public typealias MessageIconStatus = (icon: UIImage, fgColor: Color)
    public func messageStatusIcon(currentUserId: Int?) -> MessageIconStatus? {
        if !isLastMessageMine(currentUserId: currentUserId) { return nil }
        if partnerLastSeenMessageId == lastMessageVO?.id {
            return (Message.seenImage!, Color.main)
        } else if partnerLastDeliveredMessageId == lastMessageVO?.id ?? 0 {
            return (Message.seenImage!, Color.hint)
        } else if lastMessageVO?.id ?? 0 > partnerLastSeenMessageId ?? 0 {
            return (Message.sentImage!, Color.hint)
        } else { return nil }
    }
}
