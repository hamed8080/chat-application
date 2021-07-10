//
//  ParticipantsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

class ParticipantsViewModel:ObservableObject{
    
    var isLoading = false
    
    @Published
    private (set) var model = ParticipantsModel()
    
    init() {
//        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionStatusChanged(_:)), name: CONNECTION_STATUS_NAME_OBJECT, object: nil)
    }
    
//    @objc private func onConnectionStatusChanged(_ notification:NSNotification){
//        if let connectionStatus = notification.object as? ConnectionStatus{
//            model.setConnectionStatus(connectionStatus)
//            if model.participants.count == 0 && connectionStatus == .CONNECTED{
//				getParticipants()
//            }
//        }
//    }
    
//    func getParticipants() {
//        Chat.sharedInstance.getThreadParticipants(.init(count:model.count,offset: model.offset)) {[weak self] participants, uniqueId, pagination, error in
//            if let participants = participants{
//                self?.model.setParticipants(participants: pagination)
//                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
//            }
//        }cacheResponse: { [weak self] threads, uniqueId, pagination, error in
//            if let threads = threads{
//                self?.model.setParticipants(participants: participants)
//                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
//            }
//        }
//    }
//
//    func loadMore(){
//        if !model.hasNext() || isLoading{return}
//        isLoading = true
//        model.preparePaginiation()
//        Chat.sharedInstance.getThreads(.init(count:model.count,offset: model.offset)) {[weak self] threads, uniqueId, pagination, error in
//            if let threads = threads{
//                self?.model.appendThreads(threads: threads)
//                self?.isLoading = false
//            }
//        }cacheResponse: { [weak self] threads, uniqueId, pagination, error in
//            if let threads = threads{
//                self?.model.setThreads(threads: threads)
//                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
//            }
//        }
//    }
    
//    func refresh() {
//        clear()
//		getParticipants()
//    }
//
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
//        model.setupPreview()
    }
	
	func muteUnMuteThread(_ thread:Conversation){
		
	}
	
	func deleteThread(_ thread:Conversation){
		
	}
}
