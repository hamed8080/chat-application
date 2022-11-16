//
//  CallParticipantsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine

class CallParticipantsViewModel:ObservableObject{
    
    lazy var callId:Int = -1
    
    @Published
    private (set) var model = CallParticipantsModel()
    
    @Published
    var isLoading = false
    
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    
    func getParticipantsIfConnected() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if status == .CONNECTED && self.callId != -1{
                self.getActiveParticipants()
            }
        }
    }
    
    func getActiveParticipants() {
        isLoading = true
        Chat.sharedInstance.activeCallParticipants(.init(subjectId: callId)) { callParticipants, uniqueId, error in
            self.isLoading = false
            if let callParticipants = callParticipants{
                self.model.setCallParticipants(callParticipants: callParticipants)
            }
        }
    }
    
    func refresh() {
        clear()
		getActiveParticipants()
    }
    
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
        model.setupPreview()
    }
}
