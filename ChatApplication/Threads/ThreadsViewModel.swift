//
//  ThreadsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

class ThreadsViewModel:ObservableObject{
    
    var isLoading = false
    
    @Published
    private (set) var model = ThreadsModel()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionStatusChanged(_:)), name: CONNECTION_STATUS_NAME_OBJECT, object: nil)
    }
    
    @objc private func onConnectionStatusChanged(_ notification:NSNotification){
        if let connectionStatus = notification.object as? ConnectionStatus{
            model.setConnectionStatus(connectionStatus)
            if model.threads.count == 0 && connectionStatus == .CONNECTED{
                getThreads()
            }
        }
    }
    
    func getThreads() {
        Chat.sharedInstance.getThreads(.init(count:model.count,offset: model.offset)) {[weak self] threads, uniqueId, pagination, error in
            if let threads = threads{
                self?.model.setThreads(threads: threads)
                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
            }
        }cacheResponse: { [weak self] threads, uniqueId, pagination, error in
            if let threads = threads{
                self?.model.setThreads(threads: threads)
                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
            }
        }
    }
    
    func loadMore(){
        if !model.hasNext() || isLoading{return}
        isLoading = true
        model.preparePaginiation()
        Chat.sharedInstance.getThreads(.init(count:model.count,offset: model.offset)) {[weak self] threads, uniqueId, pagination, error in
            if let threads = threads{
                self?.model.appendThreads(threads: threads)
                self?.isLoading = false
            }
        }cacheResponse: { [weak self] threads, uniqueId, pagination, error in
            if let threads = threads{
                self?.model.setThreads(threads: threads)
                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
            }
        }
    }
    
    func refresh() {
        clear()
        getThreads()
    }
    
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
        model.setupPreview()
    }
    
	
	func pinUnpinThread(_ thread:Conversation){
		guard let id = thread.id else{return}
		if thread.pin == false{
			Chat.sharedInstance.pinThread(.init(threadId: id)) { threadId, uniqueId, error in
				if error == nil && threadId != nil{
					self.model.pinThread(thread)
				}
			}
		}else{
			Chat.sharedInstance.unpinThread(.init(threadId: id)) { threadId, uniqueId, error in
				if error == nil && threadId != nil{
					self.model.unpinThread(thread)
				}
			}
		}
	}
	
	func muteUnMuteThread(_ thread:Conversation){
		
	}
	
	func deleteThread(_ thread:Conversation){
		
	}
}
