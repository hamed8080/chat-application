//
//  ParticipantsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine
import SwiftUI

class ParticipantsViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    lazy var threadId:Int = -1
    
    @Published
    private (set) var model = ParticipantsModel()
    
    private (set) var cancellableSet: Set<AnyCancellable> = []
    
    func getParticipantsIfConnected() {
        AppState.shared.$connectionStatus.sink { status in
            if status == .CONNECTED && self.threadId != -1{
                self.getParticipants()
            }
        }
        .store(in: &cancellableSet)
        
        NotificationCenter.default.publisher(for: THREAD_EVENT_NOTIFICATION_NAME)
            .compactMap{$0.object as? ThreadEventTypes}
            .sink { event in
                if case .threadRemoveParticipants(let removedParticipants) = event {
                    withAnimation {
                        removedParticipants.forEach { participant in
                            self.model.removeParticipant(participant)
                        }
                    }
                }
            }
            .store(in: &cancellableSet)
    }
    
    func getParticipants() {
        
        Chat.sharedInstance.getThreadParticipants(.init(threadId: threadId)) {[weak self] participants, uniqueId, pagination, error in
            if let participants = participants{
                self?.model.setHasNext(pagination?.hasNext ?? false)
                self?.model.setParticipants(participants: participants)
            }
        }cacheResponse: { [weak self] participants, uniqueId, pagination, error in
            if let participants = participants{
                self?.model.setHasNext(pagination?.hasNext ?? false)
                self?.model.setParticipants(participants: participants)
            }
        }
    }

    func loadMore(){
        if !model.hasNext || isLoading{return}
        isLoading = true
        model.preparePaginiation()
        
        Chat.sharedInstance.getThreadParticipants(.init(threadId: threadId)) { [weak self] participants, uniqueId, pagination, error in
            if let participants = participants{
                self?.model.appendParticipants(participants: participants)
                self?.isLoading = false
            }
        } cacheResponse: {[weak self]  participants, uniqueId, pagination, error in
            if let participants = participants{
                self?.model.setParticipants(participants: participants)
            }
        }
    }
    
    func refresh() {
        clear()
        getParticipants()
    }
    
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
        model.setupPreview()
    }

    func muteUnMuteThread(_ thread:Conversation){

    }

    func deleteThread(_ thread:Conversation){

    }
    
    func removePartitipant(_ participant:Participant){
        guard let id = participant.id else {return}
        Chat.sharedInstance.removeParticipants(.init(participantId: id, threadId: threadId)) { [weak self]  participant, uniqueId, error in
            if error == nil , let participant = participant?.first{
                self?.model.removeParticipant(participant)
            }
        }
    }
}
