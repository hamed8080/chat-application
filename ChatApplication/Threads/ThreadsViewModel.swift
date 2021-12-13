//
//  ThreadsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine
import SwiftUI

class ThreadsViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    var centerIsLoading = false
    
    @Published
    private (set) var model = ThreadsModel()
    
    @Published var toggleThreadContactPicker = false
    
    @AppStorage("Threads", store: UserDefaults.group) var threadsData:Data?
    
    private (set) var connectionStatusCancelable    : AnyCancellable? = nil
    private (set) var messageCancelable             : AnyCancellable? = nil
    private (set) var systemMessageCancelable       : AnyCancellable? = nil
    private (set) var isFirstTimeConnectedRequestSuccess = false
    
    init() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.isFirstTimeConnectedRequestSuccess == false && status == .CONNECTED{
                self.getThreads()
            }
        }
        messageCancelable = NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap{$0.object as? MessageEventModel}
            .sink { messageEvent in
                if messageEvent.type == .MESSAGE_NEW{
                    self.model.addNewMessageToThread(messageEvent)
                }
            }
        
        systemMessageCancelable = NotificationCenter.default.publisher(for: SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME)
            .compactMap{$0.object as? SystemEventModel}
            .sink { systemMessageEvent in
                self.startTyping(systemMessageEvent)
            }
        
        getOfflineThreads()
    }
    
    func getThreads() {
        Chat.sharedInstance.getThreads(.init(count:model.count,offset: model.offset)) {[weak self] threads, uniqueId, pagination, error in
            if let threads = threads{
                self?.isFirstTimeConnectedRequestSuccess = true
                self?.model.appendThreads(threads: threads)
                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
                if let data = try? JSONEncoder().encode(threads){
                    self?.threadsData = data
                }
            }
            self?.isLoading = false
        }
    }
    
    func getOfflineThreads(){
        let req = ThreadsRequest(count:model.count,offset: model.offset)
        CacheFactory.get(useCache: true, cacheType: .GET_THREADS(req)) { response in
            let pagination  = Pagination(count: req.count, offset: req.offset, totalCount: CMConversation.crud.getTotalCount())
            if let threads = response.cacheResponse as? [Conversation]{
                self.model.setThreads(threads: threads)
                self.model.setContentCount(totalCount: pagination.totalCount)
            }
        }
    }
    
    func loadMore(){
        if !model.hasNext() || isLoading{return}
        isLoading = true
        model.preparePaginiation()
        getThreads()
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
                self.model.muteUnMuteThread(threadId, isMute: true)
            }
        }else{
            Chat.sharedInstance.unmuteThread(.init(threadId: threadId)) { threadId, uniqueId, error in
                self.model.muteUnMuteThread(threadId, isMute: false)
            }
        }
    }
    
    func clearHistory(_ thread:Conversation){
        guard let threadId = thread.id else {return}
        Chat.sharedInstance.clearHistory(.init(threadId: threadId)) { threadId, uniqueId, error in
            if let threadId = threadId{
                print("thread history deleted with threadId:\(threadId)")
            }
        }
    }
    
    func spamPVThread(_ thread:Conversation){
        guard let threadId = thread.id else {return}
        Chat.sharedInstance.spamPvThread(SpamThreadRequest(threadId: threadId)) { blockedUser, uniqueId, error in
        }
    }
    
    func deleteThread(_ thread:Conversation){
        guard let threadId = thread.id else {return}
        Chat.sharedInstance.closeThread(.init(threadId: threadId)) { closedThreadId, uniqueId, error in
            Chat.sharedInstance.leaveThread(.init(threadId: threadId)) { removedThread, unqiuesId, error in
                self.model.removeThread(thread)
            }
        }
    }
    
    func setViewAppear(appear:Bool){
        model.setViewAppear(appear: appear)
    }
    
    var lastIsTypingTime = Date()
    func startTyping(_ systemMessageEvent:SystemEventModel) {
        if systemMessageEvent.type == .IS_TYPING, model.addTypingThread(systemMessageEvent){
            lastIsTypingTime = Date()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
              if self.lastIsTypingTime.advanced(by: 1) < Date(){
                    self.model.removeTypingThread(systemMessageEvent)
                    timer.invalidate()
                }
            }
        }else{
            lastIsTypingTime = Date()
        }
    }
    
    func createThread(_ model:StartThreadResultModel){
        centerIsLoading = true
        let invitees = model.selectedContacts.compactMap { contact in
            Invitee(id: "\(contact.id ?? 0)", idType: .TO_BE_USER_CONTACT_ID)
        }
        Chat.sharedInstance.createThread(.init(invitees: invitees, title: model.title, type:model.type)) { thread, uniqueId, error in
            if let thread = thread{
                AppState.shared.selectedThread = thread
            }
            self.centerIsLoading = false
        }
    }
    
    func searchInsideAllThreads(text:String){
        //not implemented yet
//        Chat.sharedInstance.
    }
    
}
