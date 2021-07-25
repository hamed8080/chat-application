//
//  CallsHistoryViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine

class CallsHistoryViewModel:ObservableObject{
    
    @Published
    var isLoading                       = false
    
    @Published
    private (set) var model = CallsHistoryModel()
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    
    init() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.model.calls.count == 0 && status == .CONNECTED{
                self.getCallsHistory()
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
