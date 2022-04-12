//
//  AppState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import SwiftUI
import FanapPodChatSDK

class AppState: ObservableObject {
    
    static let shared = AppState()
    
    var user:User? = nil
    
    @Published
    var callLogs:[URL]? = nil
    
    @Published
    var connectionStatus:ConnectionStatus = .Connecting{
        didSet{
            setConnectionStatus(connectionStatus)
        }
    }
    
    @Published
    var connectionStatusString = ""
    
    @Published
    var selectedThread:Conversation? = nil
    
    func setConnectionStatus(_ status:ConnectionStatus){
        if status == .CONNECTED{
            connectionStatusString = ""
        }else{
            connectionStatusString = String(describing: status) + " ..."
        }
    }
    
	private init() {}
    
    //get cahe user from databse for working fast with something like showing message rows
    func setCachedUser(){
        CacheFactory.get(useCache: true, cacheType: .USER_INFO) { response in
            self.user = response.cacheResponse as? User
        }
    }
    
}
