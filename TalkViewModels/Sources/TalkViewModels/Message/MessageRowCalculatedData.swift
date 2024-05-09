//
//  MessageRowCalculatedData.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatModels
import SwiftUI

public struct MessageRowCalculatedData {
    public var isCalculated = false
    public var timeString: String = ""
    public var isMe: Bool = false
    public var fileMetaData: FileMetaData?
    public var isEnglish = true
    public var isReplyImage: Bool = false
    public var callDateText: String = ""
    public var callTypeKey = ""
    public var replyLink: String?
    public var participantColor: Color? = nil
    public var computedFileSize: String? = nil
    public var extName: String? = nil
    public var fileName: String? = nil
    public var addOrRemoveParticipantsAttr: AttributedString? = nil
    public var avatarColor: Color = .blue
    public var avatarSplitedCharaters = ""
    public var isInTwoWeekPeriod: Bool = false
    public var localizedReplyFileName: String? = nil
    public var markdownTitle = AttributedString()
    public var isFirstMessageOfTheUser: Bool = false
    public var isLastMessageOfTheUser: Bool = false
    public var canShowIconFile: Bool = false
    public var groupMessageParticipantName: String?
    public var image: UIImage = MessageRowViewModel.emptyImage
    public var canEdit: Bool = false
    public init() {}
}
