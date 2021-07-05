//
//  CallsHistoryViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

class CallsHistoryViewModel:ObservableObject{
    
    var isLoading                       = false
    
    @Published
    private (set) var model = CallsHistoryModel()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionStatusChanged(_:)), name: CONNECTION_STATUS_NAME_OBJECT, object: nil)
    }
    
    @objc private func onConnectionStatusChanged(_ notification:NSNotification){
        if let connectionStatus = notification.object as? ConnectionStatus{
            model.setConnectionStatus(connectionStatus)
            if model.calls.count == 0 && connectionStatus == .CONNECTED{
                getCallsHistory()
            }
        }
    }
    
    func getCallsHistory() {
        Chat.sharedInstance.callsHistory(.init(count:model.count,offset: model.offset)) {[weak self] calls, uniqueId, pagination, error in
            if let calls = calls{
                self?.model.setCalls(calls: calls)
                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
            }
        }
    }
    
    func loadMore(){
        if !model.hasNext() || isLoading{return}
        isLoading = true
        model.preparePaginiation()
        Chat.sharedInstance.callsHistory(.init(count:model.count,offset: model.offset)) {[weak self] calls, uniqueId, pagination, error in
            if let calls = calls{
                self?.model.appendCalls(calls: calls)
                self?.isLoading = false
            }
        }
    }
    
    func refresh() {
        clear()
        getCallsHistory()
    }
    
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
        model.setupPreview()
    }
}
