//
//  SceneDelegate.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import SwiftUI
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = HomeContentView()

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = CustomUIHostinViewController(rootView: contentView) // CustomUIHosting Needed for change status bar color per page
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        if url.absoluteString.contains("Widget") == true {
            let threadIdString = url.absoluteString.replacingOccurrences(of: "Widget://link-", with: "")
            let threadId = Int(threadIdString) ?? 0
            AppState.shared.showThread(threadId: threadId)
        }

        if let userName = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.first(where: { $0.name == "userName" })?.value {
            AppState.shared.showThread(userName: userName)
        }
    }

    func sceneDidDisconnect(_: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_: UIScene) {
        TokenManager.shared.startTimerToGetNewToken()
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
