//
//  ThreadViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine

class ThreadViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    private (set) var model = ThreadModel()
    
    private (set) var thread:Conversation
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    
    init(thread:Conversation) {
        self.thread = thread
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.model.messages.count == 0 && status == .CONNECTED{
                self.getMessagesHistory()
            }
        }
    }
    
    func loadMore(){
        if !model.hasNext() || isLoading{return}
        isLoading = true
        model.preparePaginiation()
        getMessagesHistory()
    }
    
    func getMessagesHistory(){
        guard let threadId = thread.id else{return}
        Chat.sharedInstance.getHistory(.init(threadId: threadId, count:model.count,offset: model.offset)) {[weak self] messages, uniqueId, pagination, error in
            if let messages = messages{
                self?.model.appendMessages(messages: messages)
                self?.isLoading = false
            }
        }cacheResponse: { [weak self] messages, uniqueId, error in
            if let messages = messages{
                self?.model.setMessages(messages: messages)
            }
        }
    }
    
    func refresh() {
        clear()
        getMessagesHistory()
    }
    
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
        model.setupPreview()
    }
    
	
	func pinUnpinMessage(_ message:Message){
		guard let id = message.id else{return}
		if message.pinned == false{
			Chat.sharedInstance.pinMessage(.init(messageId: id)) { messageId, uniqueId, error in
				if error == nil && messageId != nil{
					self.model.pinMessage(message)
				}
			}
		}else{
			Chat.sharedInstance.unpinMessage(.init(messageId: id)) { messageId, uniqueId, error in
				if error == nil && messageId != nil{
					self.model.unpinMessage(message)
				}
			}
		}
	}
	
    func deleteMessage(_ message:Message){
        guard let messageId = message.id else {return}
        Chat.sharedInstance.deleteMessage(.init(messageId: messageId)) { deletedMessage, uniqueId, error in
            self.model.deleteMessage(message)
        }
	}
}
