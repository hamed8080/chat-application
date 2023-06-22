//
//  MessageRowCalculationViewModel.swift
//  ChatApplication
//
//  Created by hamed on 3/9/23.
//

import Chat
import MapKit
import SwiftUI
import ChatAppExtensions
import ChatModels

public final class MessageRowCalculationViewModel: ObservableObject {
    public var isCalculated = false
    @Published public var isEnglish = true
    @Published public var widthOfRow: CGFloat = 128
    @Published public var markdownTitle = AttributedString()
    public var calculatedMaxAndMinWidth: CGFloat = 128
    public var addressDetail: String?
    public var timeString: String = ""
    public var fileSizeString: String?
    public static var avatarSize: CGFloat = 24
    public init() {}

    @MainActor
    public func calculate(message: Message) {
        if isCalculated { return }
        isCalculated = true
        Task(priority: .background) {
            let isEnglish = message.message?.isEnglishString ?? true
            let widthOfRow = calculateWidthOfMessage(message)
            let markdownTitle = message.markdownTitle
            let addressDetail = await message.addressDetail
            let timeString = message.time?.date.timeAgoSinceDateCondense ?? ""
            let fileSizeString = message.fileMetaData?.file?.size?.toSizeString
            await MainActor.run {
                withAnimation { [weak self] in
                    self?.addressDetail = addressDetail
                    self?.isEnglish = isEnglish
                    self?.widthOfRow = widthOfRow
                    self?.markdownTitle = markdownTitle
                    self?.timeString = timeString
                    self?.fileSizeString = fileSizeString
                    self?.objectWillChange.send()
                }
            }
        }
    }

    public func footerWidth(_ message: Message) -> CGFloat {
        let timeWidth = message.time?.date.timeAgoSinceDateCondense?.widthOfString(usingFont: UIFont.systemFont(ofSize: 24)) ?? 0
        let fileSizeWidth = fileSizeString?.widthOfString(usingFont: UIFont.systemFont(ofSize: 24)) ?? 0
        let statusWidth: CGFloat = message.isMe(currentUserId: AppState.shared.user?.id) ? 14 : 0
        let isEditedWidth: CGFloat = message.edited ?? false ? 24 : 0
        let messageStatusIconWidth: CGFloat = 24
        return timeWidth + fileSizeWidth + statusWidth + isEditedWidth + messageStatusIconWidth
    }

    public lazy var maxAllowedWidth: CGFloat = {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let max: CGFloat = isIpad ? 420 : 320
        return max
    }()

    public func minWidth(_ message: Message) -> CGFloat {
        let hasReplyMessage = message.replyInfo != nil
        return message.isUnsentMessage ? 148 : message.isFileType ? 164 : hasReplyMessage ? 246 : 128
    }

    public func headerWidth(_ message: Message) -> CGFloat {
        let spacing: CGFloat = 8
        let padding: CGFloat = 16
        return (message.participant?.name?.widthOfString(usingFont: .systemFont(ofSize: 22)) ?? 0) + MessageRowCalculationViewModel.avatarSize + spacing + padding
    }

    public func calculateWidthOfMessage(_ message: Message) -> CGFloat {
        let imageWidth: CGFloat = CGFloat(message.fileMetaData?.file?.actualWidth ?? 0)
        let messageWidth = message.messageTitle.widthOfString(usingFont: UIFont.systemFont(ofSize: 16)) + 16
        let headerWidth = headerWidth(message)
        let footerWidth = footerWidth(message)
        let uploadFileProgressWidth: CGFloat = message.isUploadMessage == true ? 128 : 0
        let unSentMessageWidth: CGFloat = message.isUnsentMessage == true ? messageWidth : 0
        let contentWidth = [imageWidth, messageWidth, headerWidth, footerWidth, uploadFileProgressWidth, unSentMessageWidth].max() ?? 0
        let calculatedWidth: CGFloat = min(contentWidth, maxAllowedWidth)
        return calculatedWidth
    }
}
