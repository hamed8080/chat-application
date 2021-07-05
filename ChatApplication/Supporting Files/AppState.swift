//
//  AppState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import SwiftUI
import FanapPodChatSDK

class AppState: ObservableObject {
    
    @Published
    var showCallView = false
    
    @Published var dark:Bool = false
    
    
    var selectedContacts :[Contact] = []
    var isP2PCalling     :Bool      = false
    var callThreadId     :Int?      = nil
    var groupName        :String?   = nil
    
    var titleOfCalling:String{
        if isP2PCalling{
            return selectedContacts.first?.linkedUser?.username ?? "\(selectedContacts.first?.firstName ?? "") \(selectedContacts.first?.lastName ?? "")"
        }else{
            return groupName ?? "Group"
        }
    }

}
