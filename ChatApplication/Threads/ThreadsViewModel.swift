//
//  ThreadsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine

class ThreadsViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    private (set) var model = ThreadsModel()
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    
    init() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.model.threads.count == 0 && status == .CONNECTED{
                self.getThreads()
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
        guard let threadId = thread.id else {return}
        if thread.mute == false{
            Chat.sharedInstance.muteThread(.init(threadId: threadId)) { threadId, uniqueId, error in
                
            }
        }else{
            Chat.sharedInstance.unmuteThread(.init(threadId: threadId)) { threadId, uniqueId, error in
                
            }
        }
	}
	
    func deleteThread(_ thread:Conversation){
        guard let threadId = thread.id else {return}
        Chat.sharedInstance.leaveThread(.init(threadId: threadId)) { removedThread, unqiuesId, error in
            self.model.removeThread(thread)
        }
	}
}
