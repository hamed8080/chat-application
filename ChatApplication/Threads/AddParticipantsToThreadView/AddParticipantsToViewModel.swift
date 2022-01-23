//
//  AddParticipantsToViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine

class AddParticipantsToViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    private (set) var model = StartThreadModel()
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    
    init() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.model.threads.count == 0 && status == .CONNECTED{
         
            }
        }
    }
    
    func setupPreview(){
        model.setupPreview()
    }
}
