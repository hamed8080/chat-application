//
//  MessageRowCalculationViewModel.swift
//  ChatApplication
//
//  Created by hamed on 3/9/23.
//

import FanapPodChatSDK
import MapKit
import SwiftUI

final class MessageRowCalculationViewModel: ObservableObject {
    var isCalculated = false
    @Published var isEnglish = true
    @Published var widthOfRow: CGFloat = 128
    @Published var markdownTitle = AttributedString()
    var calculatedMaxAndMinWidth: CGFloat = 128
    var addressDetail: String?

    init() {}

    @MainActor
    func calculate(message: Message) {
        if isCalculated { return }
        isCalculated = true
        Task(priority: .background) {
            let isEnglish = message.message?.isEnglishString ?? true
            let widthOfRow = calculateWidthOfMessage(message)
            let markdownTitle = message.markdownTitle
            let addressDetail = await message.addressDetail
            await MainActor.run {
                withAnimation { [weak self] in
                    self?.addressDetail = addressDetail
                    self?.isEnglish = isEnglish
                    self?.widthOfRow = widthOfRow
                    self?.markdownTitle = markdownTitle
                    self?.objectWillChange.send()
                }
            }
        }
    }

    func footerWidth(_ message: Message) -> CGFloat {
        let timeWidth = message.time?.date.timeAgoSinceDatecCondence?.widthOfString(usingFont: UIFont.systemFont(ofSize: 24)) ?? 0
        let fileSize = Int(message.fileMetaData?.file?.size ?? 0)
        let fileSizeWidth = fileSize.toSizeString.widthOfString(usingFont: UIFont.systemFont(ofSize: 24))
        let statusWidth: CGFloat = message.isMe ? 14 : 0
        let isEditedWidth: CGFloat = message.edited ?? false ? 24 : 0
        return timeWidth + fileSizeWidth + statusWidth + isEditedWidth
    }

    var maxAllowedWidth: CGFloat {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let max: CGFloat = isIpad ? 420 : 320
        return max
    }

    func minWidth(_ message: Message) -> CGFloat {
        let hasReplyMessage = message.replyInfo != nil
        return message.isUnsentMessage ? 148 : message.isFileType ? 164 : hasReplyMessage ? 246 : 128
    }

    func headerWidth(_ message: Message) -> CGFloat {
        let avatarWidth = SameAvatar.size
        let spacing: CGFloat = 8
        let padding: CGFloat = 16
        return (message.participant?.name?.widthOfString(usingFont: .systemFont(ofSize: 22)) ?? 0) + avatarWidth + spacing + padding
    }

    func calculateWidthOfMessage(_ message: Message) -> CGFloat {
        let messageWidth = message.messageTitle.widthOfString(usingFont: UIFont.systemFont(ofSize: 16)) + 16
        let headerWidth = headerWidth(message)
        let footerWidth = footerWidth(message)
        let calculatedWidth: CGFloat = min(messageWidth, maxAllowedWidth)
        let maxFooterAndMsg: CGFloat = max(footerWidth, calculatedWidth)
        let maxHeaderAndFooter = max(maxFooterAndMsg, headerWidth)
        let maxWidth = max(minWidth(message), maxHeaderAndFooter)
        return maxWidth
    }
}
