//
//  AppDelegate.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import ChatAppViewModels
import PushKit
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    class var shared: AppDelegate! {
        UIApplication.shared.delegate as? AppDelegate
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        AppState.shared.providerDelegate = ProviderDelegate(callManager: AppState.shared.callMananger)
        ChatDelegateImplementation.sharedInstance.createChatObject()
        UIFont.register()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func pushRegistry(_: PKPushRegistry, didUpdate _: PKPushCredentials, for _: PKPushType) {}

    func pushRegistry(_: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        defer {
            completion()
        }
        guard type == .voIP,
              let uuidString = payload.dictionaryPayload["UUID"] as? String,
              let handle = payload.dictionaryPayload["handle"] as? String,
              let hasVideo = payload.dictionaryPayload["hasVideo"] as? Bool,
              let uuid = UUID(uuidString: uuidString)
        else {
            return
        }
        AppState.shared.providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: nil)
    }
}
