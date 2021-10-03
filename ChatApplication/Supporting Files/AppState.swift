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
    
    @Published var dark:Bool = false
    
    @Published
    var connectionStatus:ConnectionStatus = .Connecting{
        didSet{
            setConnectionStatus(connectionStatus)
        }
    }
    
    @Published
    var connectionStatusString = ""
    
    @Published
    var selectedThread:Conversation? = nil{
        didSet{
            if selectedThread != nil{
                showThread = true
            }
        }
    }
    
    @Published
    var showThread = false
    
    func setConnectionStatus(_ status:ConnectionStatus){
        if status == .CONNECTED{
            connectionStatusString = ""
        }else{
            connectionStatusString = String(describing: status) + " ..."
        }
    }
    
	private init() {}
    
}
