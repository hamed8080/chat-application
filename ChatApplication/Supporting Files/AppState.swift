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
    var connectionStatus:ConnectionStatus = .Connecting
    
    @Published
    var connectionStatusString = ""
    
    func setConnectionStatus(_ status:ConnectionStatus){
        if status == .CONNECTED{
            connectionStatusString = ""
        }else{
            connectionStatusString = String(describing: status) + " ..."
        }
    }
    
	private init() {}
    
}
