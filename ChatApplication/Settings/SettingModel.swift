//
//  SettingModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct SettingModel {
    
    private (set) var currentUser           :User?  = Chat.sharedInstance.getCurrentUser()
    
    mutating func setCurrentUser(_ user:User?){
        self.currentUser = user
    }
    
}
