//
//  CallsHistoryModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct CallsHistoryModel {
    
    
    private (set) var connectionStatus:String?      = "Connecting ..."
    private (set) var count                         = 15
    private (set) var offset                        = 0
    private (set) var totalCount                    = 0
    private (set) var calls :[Call]                 = []
    
    func hasNext()->Bool{
        return calls.count < totalCount
    }
    
    mutating func setConnectionStatus(_ status:ConnectionStatus){
        if status == .CONNECTED{
            connectionStatus = ""
        }else{
            connectionStatus = String(describing: status) + " ..."
        }
    }
    
    mutating func preparePaginiation(){
        offset = calls.count
    }
    
    mutating func setContentCount(totalCount:Int){
        self.totalCount = totalCount
    }
    
    mutating func setCalls(calls:[Call]){
        self.calls = calls
    }
    
    mutating func appendCalls(calls:[Call]){
        self.calls.append(contentsOf: calls)
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.totalCount = 0
        self.calls      = []
    }

}

extension CallsHistoryModel{
    
    mutating func setupPreview(){
        let t1 = CallRow_Previews.call
        let t2 = CallRow_Previews.call
        let t3 = CallRow_Previews.call
        appendCalls(calls: [t1 , t2, t3])
    }
}
