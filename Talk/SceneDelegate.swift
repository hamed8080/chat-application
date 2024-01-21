//
//  SceneDelegate.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import UIKit
import BackgroundTasks
import Logger

final class SceneDelegate: UIResponder, UIWindowSceneDelegate, UIApplicationDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = HomeContentView()
            .font(.iransansBody)

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        TokenManager.shared.initSetIsLogin()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = CustomUIHostinViewController(rootView: contentView) // CustomUIHosting Needed for change status bar color per page
            self.window = window
            window.makeKeyAndVisible()
        }
        
        // MARK: Registering Launch Handlers for Tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "ir.pod.talk.refreshToken", using: nil) { task in
            // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
            if let task = task as? BGAppRefreshTask {
                self.handleTaskRefreshToken(task)
            }
        }
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        if url.absoluteString.contains("Widget") == true {
            let threadIdString = url.absoluteString.replacingOccurrences(of: "Widget://link-", with: "")
            let threadId = Int(threadIdString) ?? 0
            AppState.shared.showThread(thread: .init(id: threadId))
        } else if url.absoluteString.contains("ShowUser") {
            let userName = url.absoluteString.replacingOccurrences(of: "ShowUser:User?userName=", with: "")
            AppState.shared.openThreadWith(userName: userName)
        }
    }

    func sceneDidDisconnect(_: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_: UIScene) {
        AppState.shared.updateWindowMode()
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        AppState.shared.lifeCycleState = .active
    }

    func sceneWillResignActive(_: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        AppState.shared.updateWindowMode()
        AppState.shared.lifeCycleState = .inactive
    }

    func sceneWillEnterForeground(_: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        AppState.shared.lifeCycleState = .foreground
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        AppState.shared.lifeCycleState = .background
        scheduleAppRefreshToken()
    }

    private func scheduleAppRefreshToken() {
        if let ssoToken = TokenManager.shared.getSSOTokenFromUserDefaults(), let createDate = TokenManager.shared.getCreateTokenDate() {
            let timeToStart = createDate.advanced(by: Double(ssoToken.expiresIn - 50)).timeIntervalSince1970 - Date().timeIntervalSince1970
            let request = BGAppRefreshTaskRequest(identifier: "ir.pod.talk.refreshToken")
            request.earliestBeginDate = Date(timeIntervalSince1970: timeToStart)
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Could not schedule app refresh: \(error)")
            }
        }
    }

    private func handleTaskRefreshToken(_ task: BGAppRefreshTask) {
        Task { [weak self] in
            guard let self = self else { return }
            let log = Log(prefix: "TALK_APP", time: .now, message: "Start a new Task in handleTaskRefreshToken method", level: .error, type: .sent, userInfo: nil)
            NotificationCenter.logs.post(name: .logs, object: log)
            await TokenManager.shared.getNewTokenWithRefreshToken()
            scheduleAppRefreshToken() /// Reschedule again when user receive a token.
        }
    }
}
