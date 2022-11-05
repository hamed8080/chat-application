//
//  AppDelegate.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import UIKit
import PushKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    
    class var shared: AppDelegate! {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    var providerDelegate:ProviderDelegate?
    let callMananger = CallManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        providerDelegate = ProviderDelegate(callManager: callMananger)
        ChatDelegateImplementation.sharedInstance.createChatObject()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        defer {
            completion()
        }
        guard type == .voIP,
              let uuidString = payload.dictionaryPayload["UUID"] as? String,
              let handle = payload.dictionaryPayload["handle"] as? String,
              let hasVideo = payload.dictionaryPayload["hasVideo"] as? Bool,
              let uuid = UUID(uuidString: uuidString)
        else{
            return
        }
        providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: nil)
    }
    
}

