//
//  Color+.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/30/21.
//

import Foundation
import SwiftUI

extension Color {
    init(named: String) {
        self = Color(UIColor(named: named)!)
    }

    static var random: Color {
        Color(uiColor: UIColor.random())
    }

    static let darkGreen = Color("dark_green")
    static let textBlueColor = Color("text_color_blue")
    static let bgColor = Color("background")
    static let iconColor = Color("icon_color")
    static let redSoft = Color("red_soft")
    static let chatMeBg = Color("chat_me")
    static let chatSenderBg = Color("chat_sender")
    static let tableItem = Color("tableItem")
    static let replyBg = Color("reply_background")
    static let secondaryLabel = Color(UIColor.secondaryLabel)
}
