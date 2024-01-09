//
//  ColorSchemeModifier.swift
//  Talk
//
//  Created by hamed on 1/9/24.
//

import SwiftUI
import TalkViewModels

struct ColorSchemeModifier: ViewModifier {
    @State var isAppDarkModeEnabled: Bool? = AppSettingsModel.restore().isDarkModeEnabled

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(isAppDarkModeEnabled == nil ? nil : isAppDarkModeEnabled == true ? .dark : .light)
            .onReceive(NotificationCenter.default.publisher(for: .appSettingsModel), perform: { onSettingNotif($0)} )
    }

    private func onSettingNotif(_ notification: Notification) {
        if (notification.object as? AppSettingsModel)?.isDarkModeEnabled != isAppDarkModeEnabled {
            withAnimation {
                self.isAppDarkModeEnabled = AppSettingsModel.restore().isDarkModeEnabled
            }
        }
    }
}
