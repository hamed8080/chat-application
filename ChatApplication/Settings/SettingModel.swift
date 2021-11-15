//
//  SettingModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct SettingModel {
    
    private (set) var tokens                :[String]        = []
    private (set) var currentUser           :User?           = Chat.sharedInstance.getCurrentUser()
    
    mutating func setCurrentUser(_ user:User?){
        self.currentUser = user
    }
    
    mutating func addNewToken(_ token:String){
        self.tokens.append(token)
    }
    
    mutating func saveToken(_ token:String){
        //save user defualts
    }
    
    mutating func getAllTokens(){
        //get all users from user defualts
    }
}
