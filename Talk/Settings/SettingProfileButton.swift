//
//  SettingProfileButton.swift
//  Talk
//
//  Created by hamed on 11/1/23.
//

import SwiftUI
import TalkViewModels
import ChatModels
import TalkModels
import Chat

struct SettingProfileButton: View {
    @EnvironmentObject var container: ObjectsContainer
    var userConfig: UserConfig? { container.userConfigsVM.currentUserConfig }
    var user: User? { userConfig?.user }
    @StateObject var imageLoader = ImageLoaderViewModel()
    @State var isSelected = false

    var body: some View {
        Image(systemName: "gear")
            .resizable()
            .scaledToFit()
            .overlay {
                Image(uiImage: imageLoader.image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(x: imageLoader.isImageReady ? 1 : 0.001, y: imageLoader.isImageReady ? 1 : 0.001, anchor: .center)
                    .animation(.interpolatingSpring(mass: 1.0, stiffness: 0.3, damping: 0.5, initialVelocity: 0).speed(15), value: imageLoader.isImageReady)
                    .frame(width: 24, height: 24)
                    .cornerRadius(12)
                    .overlay {
                        Circle()
                            .strokeBorder(isSelected ? Color.App.primary : Color.App.bgPrimary, lineWidth: imageLoader.isImageReady ? 1 : 0)
                            .animation(.easeInOut, value: isSelected)
                    }
            }
            .onReceive(NotificationCenter.default.publisher(for: .user)) { notification in
                let event = notification.object as? UserEventTypes
                if !imageLoader.isImageReady, case let .user(response) = event, let user = response.result {
                    imageLoader.fetch(url: user.image, userName: user.name, size: .LARG)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .selectTab)) { notification in
                if let selectedTab = notification.object as? String, selectedTab == "Tab.settings" {
                    isSelected = true
                } else {
                    isSelected = false
                }
            }
    }
}


struct SettingProfileButton_Previews: PreviewProvider {
    static var previews: some View {
        SettingProfileButton()
    }
}
