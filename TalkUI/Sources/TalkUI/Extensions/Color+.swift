//
//  Color+.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 11/30/21.
//

import Foundation
import SwiftUI

public extension Color {
    init(named: String) {
        self = Color(UIColor(named: named)!)
    }

    static var random: Color {
        Color(uiColor: UIColor.random())
    }

    static let darkGreen = Color("dark_green")
    static let textBlueColor = Color("text_color_blue")
    static let bgColor = Color("bg_color")
    static let iconColor = Color("icon_color")
    static let redSoft = Color("red_soft")
    static let bgMessage = Color("bg_message")
    static let bgMessageMe = Color("bg_message_me")
    static let chatSenderBg = Color("chat_sender")
    static let tableItem = Color("tableItem")
    static let swipyBackground = Color("swipy_background")
    static let replyBg = Color("reply_background")
    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let messageText = Color("message_text")
    static let hint = Color("hint")
    static let bgInput = Color("bg_input")
    static let bgSpaceItem = Color("bg_space_item")
    static let hintText = Color("hint_text")
    static let main = Color("main")
    static let bgChatBox = Color("bg_chatbox")
    static let placeholder = Color("placeholder")
    static let bgChatContainer = Color("bg_chat_container")
    static let bgMain = Color("bg_main")
    static let bgPin = Color("bg_pin")
    static let separator = Color("separator")
}
