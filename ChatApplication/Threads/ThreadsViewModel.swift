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
    
    @Published
    var showAddParticipants = false
    
    @Published
    var showAddToTags       = false
    
    @Published
    var connectionStatus:ConnectionStatus     = .Connecting
    
    private (set) var connectionStatusCancelable    : AnyCancellable? = nil
    private (set) var messageCancelable             : AnyCancellable? = nil
    private (set) var systemMessageCancelable       : AnyCancellable? = nil
    private (set) var threadCancelable              : AnyCancellable? = nil
    
    private (set) var isFirstTimeConnectedRequestSuccess = false
    
    @Published
    private (set) var tagViewModel = TagsViewModel()
    
    init() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.isFirstTimeConnectedRequestSuccess == false && status == .CONNECTED{
                self.getThreads()
            }
             self.connectionStatus = status
        }
        messageCancelable = NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap{$0.object as? MessageEventModel}
            .sink { messageEvent in
                if messageEvent.type == .MESSAGE_NEW{
                    self.model.addNewMessageToThread(messageEvent)
                }
            }
        
        threadCancelable = NotificationCenter.default.publisher(for: THREAD_EVENT_NOTIFICATION_NAME)
            .compactMap{$0.object as? ThreadEventModel}
            .sink { threadEvent in
                if threadEvent.type == .THREAD_NEW, let threads = threadEvent.threads {
                    withAnimation {
                        self.model.appendThreads(threads: threads)
                    }
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
                let threadIds = threads.compactMap{$0.id}
                self?.getActiveCallsListToJoin(threadIds)
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
        Chat.sharedInstance.leaveThread(.init(threadId: threadId, clearHistory: true)) { user, unqiuesId, error in
            self.model.removeThread(thread)
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
    
    var selectedThraed:Conversation?
    func showAddParticipants(_ thread:Conversation){
        self.selectedThraed = thread
        showAddParticipants.toggle()
    }
    
    func addParticipantsToThread(_ contacts:[Contact] ){
        centerIsLoading = true
        guard let threadId = selectedThraed?.id else {
            return
        }

        let participants = contacts.compactMap { contact in
            AddParticipantRequest(userName: contact.linkedUser?.username ?? "", threadId: threadId)
        }
        
        Chat.sharedInstance.addParticipants(participants) { thread, uniqueId, error in
            if let thread = thread{
                AppState.shared.selectedThread = thread
            }
            self.centerIsLoading = false
        }
    }
    
    func showAddThreadToTag(_ thread:Conversation){
        self.selectedThraed = thread
        showAddToTags.toggle()
    }
    
    func threadAddedToTag(_ tag:Tag){
        if let selectedThraed = selectedThraed {
            isLoading = true
            tagViewModel.addThreadToTag(tag: tag, thread: selectedThraed){ tagParticipants, success in
                self.isLoading = false
            }
        }
    }
    
    func getActiveCallsListToJoin(_ threadIds:[Int]){
        Chat.sharedInstance.getCallsToJoin(.init(threadIds: threadIds)) { calls, uniqueId, error in
            if let calls = calls{
                self.model.addActiveCalls(calls)
            }
        }
    }
    
    func joinToCall(_ call:Call){
        let callState = CallState.shared
        Chat.sharedInstance.acceptCall(.init(callId:call.id, client: .init(mute: false , video: false)))
        withAnimation(.spring()){
            callState.model.setIsJoinCall(true)
            callState.model.setShowCallView(true)
        }
        CallState.shared.model.setAnswerWithVideo(answerWithVideo: false, micEnable: false)
        AppDelegate.shared.callMananger.callAnsweredFromCusomUI()
    }
    
}
