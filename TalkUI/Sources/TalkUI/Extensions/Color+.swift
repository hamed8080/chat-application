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
        public static let textPrimary = Color("text_primary")
        public static let textSecondary = Color("text_secondary")
        public static let textPlaceholder = Color("text_placeholder")
        public static let iconPrimary = Color("iconPrimary")
        public static let iconSecondary = Color("icon_secondary")
        public static let bgPrimary = Color("bg_primary")
        public static let bgSecondary = Color("bg_secondary")
        public static let bgIcon = Color("bg_icon")
        public static let bgSpacer = Color("bg_spacer")
        public static let bgBadgeMute = Color("bg_badge_mute")
        public static let bgBadgeUnMute = Color("bg_badge_unMute")
        public static let bgChatMe = Color("bg_chat_me")


        public static let uired = UIColor(named: "red")
        public static let uiorange = UIColor(named: "orange")
        public static let uiyellow = UIColor(named: "yellow")
        public static let uigreen = UIColor(named: "green")
        public static let uimint = UIColor(named: "mint")
        public static let uiteal = UIColor(named: "teal")
        public static let uicyan = UIColor(named: "cyan")
        public static let uiblue = UIColor(named: "blue")
        public static let uiindigo = UIColor(named: "indigo")
        public static let uipurple = UIColor(named: "purple")
        public static let uipink = UIColor(named: "pink")
        public static let uibrown = UIColor(named: "brown")
        public static let uiwhite = UIColor(named: "white")
        public static let uiblack = UIColor(named: "black")
        public static let uigrayHalf = UIColor(named: "gray_half")
        public static let uigray1 = UIColor(named: "gray_1")
        public static let uigray2 = UIColor(named: "gray_2")
        public static let uigray3 = UIColor(named: "gray_3")
        public static let uigray4 = UIColor(named: "gray_4")
        public static let uigray5 = UIColor(named: "gray_5")
        public static let uigray6 = UIColor(named: "gray_6")
        public static let uigray7 = UIColor(named: "gray_7")
        public static let uigray8 = UIColor(named: "gray_8")
        public static let uigray9 = UIColor(named: "gray_9")
        public static let uiseparator = UIColor(named: "separator")
        public static let uidivider = UIColor(named: "divider")
        public static let uiprimary = UIColor(named: "primary")
        public static let uiprimaryDark = UIColor(named: "primary_dark")
        public static let uitext = UIColor(named: "text")
        public static let uihint = UIColor(named: "hint")
        public static let uiplaceholder = UIColor(named: "placeholder")
        public static let uilink = UIColor(named: "link")
        public static let uitextOverlay = UIColor(named: "text_overlay")
        public static let uitextDisabled = UIColor(named: "text_disabled")
        public static let uibgPrimary = UIColor(named: "bg_primary")
        public static let uibtnDownload = UIColor(named: "btn_download")
        public static let uibgSecond = UIColor(named: "bg_second")
        public static let uibgTertiary = UIColor(named: "bg_tertiary")
        public static let uibgContextMenu = UIColor(named: "bg_context_menu")
        public static let uibgInput = UIColor(named: "bg_input")
        public static let uibgInputDark = UIColor(named: "bg_input_dark")
        public static let uibgInputError = UIColor(named: "bg_input_error")
        public static let uibgToast = UIColor(named: "bg_toast")
        public static let uibgNavigation = UIColor(named: "bg_navigation")
        public static let uibgChatUser = UIColor(named: "bg_chat_user")
        public static let uibgChatMe = UIColor(named: "bg_chat_me")
    }
}
