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
    private (set) var thread:Conversation?
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    private (set) var messageCancelable:AnyCancellable? = nil
    private (set) var systemMessageCancelable:AnyCancellable? = nil
    
    init(){
        messageCancelable = NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap{$0.object as? MessageEventModel}
            .sink { messageEvent in
                if messageEvent.type == .MESSAGE_NEW , let message = messageEvent.message, self.model.isViewDisplaying{
                    self.model.appendMessage(message)
                }
            }
        systemMessageCancelable = NotificationCenter.default.publisher(for: SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME)
            .compactMap{$0.object as? SystemEventModel}
            .sink { systemMessageEvent in
                if systemMessageEvent.type == .IS_TYPING && systemMessageEvent.threadId == self.thread?.id{
                    "typing".isTypingAnimationWithText { startText in
                        self.model.setIsTypingText(isTypingText: startText)
                    } onChangeText: { text in
                        self.model.setIsTypingText(isTypingText: text)
                    } onEnd: {
                        self.model.setIsTypingText(isTypingText: nil)
                    }
                }
            }        
    }
    
    //when viewAppreaed this method called and now we can start to retreive thread message
    func setThread(thread:Conversation){
        self.thread = thread
        getMessagesHistory()
    }
    
    func loadMore(){
        if !model.hasNext() || isLoading{return}
        isLoading = true
        model.preparePaginiation()
        getMessagesHistory()
    }
    
    func getMessagesHistory(){
        guard let threadId = thread?.id else{return}
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
    
    
    func sendTextMessage(_ textMessage:String){
        guard let threadId = thread?.id else {return}
        let req = NewSendTextMessageRequest(threadId: threadId,
                                            textMessage: textMessage,
                                            messageType: .TEXT)
        Chat.sharedInstance.sendTextMessage(req) { uniqueId in
            
        } onSent: { response, uniqueId, error in
            
        } onSeen: { response, uniqueId, error in
            
        } onDeliver: { response, uniqueId, error in
            
        }
    }
    
    func setViewAppear(appear:Bool){
        model.setViewAppear(appear: appear)
    }
    
    var typingTimer:Timer? = nil
    
    func sendIsTyping(){
        if typingTimer == nil , let threadId = thread?.id{
            Chat.sharedInstance.snedStartTyping(threadId: threadId)
            typingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in
                Chat.sharedInstance.sendStopTyping()
                self.typingTimer = nil
                timer.invalidate()
            })
        }
    }
    
    func searchInsideThreadMessages(_ text:String){
        //-FIXME: add when merger with serach branch
//        Chat.sharedInstance.searchThread
    }
    
    func muteUnMute(){
        guard let threadId = thread?.id else {return}
        if thread?.mute == false{
            Chat.sharedInstance.muteThread(.init(threadId: threadId)) { threadId, uniqueId, error in
                
            }
        }else{
            Chat.sharedInstance.unmuteThread(.init(threadId: threadId)) { threadId, uniqueId, error in
                
            }
        }
    }
}
