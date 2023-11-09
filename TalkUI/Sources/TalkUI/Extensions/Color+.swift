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

    struct App {
        public static let red = Color("red")
        public static let orange = Color("orange")
        public static let yellow = Color("yellow")
        public static let green = Color("green")
        public static let mint = Color("mint")
        public static let teal = Color("teal")
        public static let cyan = Color("cyan")
        public static let blue = Color("blue")
        public static let indigo = Color("indigo")
        public static let purple = Color("purple")
        public static let pink = Color("pink")
        public static let brown = Color("brown")
        public static let white = Color("white")
        public static let black = Color("black")
        public static let grayHalf = Color("gray_half")
        public static let gray1 = Color("gray_1")
        public static let gray2 = Color("gray_2")
        public static let gray3 = Color("gray_3")
        public static let gray4 = Color("gray_4")
        public static let gray5 = Color("gray_5")
        public static let gray6 = Color("gray_6")
        public static let gray7 = Color("gray_7")
        public static let gray8 = Color("gray_8")
        public static let gray9 = Color("gray_9")
        public static let separator = Color("separator")
        public static let divider = Color("divider")
        public static let primary = Color("primary")
        public static let primaryDark = Color("primary_dark")
        public static let text = Color("text")
        public static let hint = Color("hint")
        public static let placeholder = Color("placeholder")
        public static let link = Color("link")
        public static let textOverlay = Color("text_overlay")
        public static let textDisabled = Color("text_disabled")
        public static let bgPrimary = Color("bg_primary")
        public static let btnDownload = Color("btn_download")
        public static let bgSecond = Color("bg_second")
        public static let bgTertiary = Color("bg_tertiary")
        public static let bgContextMenu = Color("bg_context_menu")
        public static let bgInput = Color("bg_input")
        public static let bgInputDark = Color("bg_input_dark")
        public static let bgInputError = Color("bg_input_error")
        public static let bgToast = Color("bg_toast")
        public static let bgNavigation = Color("bg_navigation")
        public static let bgChatUser = Color("bg_chat_user")
        public static let bgChatMe = Color("bg_chat_me")
    }
}
