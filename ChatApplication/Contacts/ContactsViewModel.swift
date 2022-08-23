//
//  ContactsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine
import SwiftUI

class ContactsViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    private (set) var model = ContactsModel()
    
    @Published
    public var isInEditMode                    = false

    @Published
    public var isAllSelected                   = false
    
    @Published
    public var navigateToAddOrEditContact      = false
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    
    private (set) var isFirstTimeConnectedRequestSuccess = false
    
    @Published
    var connectionStatus:ConnectionStatus     = .Connecting
    
    init() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.isFirstTimeConnectedRequestSuccess == false  && status == .CONNECTED{
                self.getContacts()
                // TODO: Fix sync contacts it has problem to syncing
//                Chat.sharedInstance.syncContacts { contacts, uniqueId, error in
//                    print("sync contact part count: \(contacts?.count ?? 0 )")
//                } completion: { completed, uniqueId, error in
//                    print("sync contact completed!!")
//                }
            }
            self.connectionStatus = status
        }
        getOfflineContacts()
    }
    
    func getContacts() {
        Chat.sharedInstance.getContacts(.init(count:model.count,offset: model.offset)) { [weak self] contacts, uniqueId, pagination, error in
            if let contacts = contacts{
                withAnimation {
                    self?.isFirstTimeConnectedRequestSuccess = true
                    self?.model.setHasNext(pagination?.hasNext ?? false)
                    self?.model.setContacts(contacts: contacts)
                    self?.model.setMaxContactsCountInServer(count: (pagination as? PaginationWithContentCount)?.totalCount ?? 0)
                }
            }
        }
    }
    
    func getOfflineContacts() {
        let req = ContactsRequest(count:model.count,offset: model.offset)
        CacheFactory.get(useCache: true, cacheType: .GET_CASHED_CONTACTS(req)) { response in
            let contacts = response.cacheResponse as? [Contact]
            withAnimation {
                self.model.setContacts(contacts: contacts)
                self.model.setMaxContactsCountInServer(count: CMContact.crud.getTotalCount())
            }
        }
    }

    func resetModelOffset() {
        model.resetOffset()
    }

    func searchContact(_ searchContact:String){
        if searchContact.count <= 0{
            self.model.setSearchedContacts([])
            return
        }
        Chat.sharedInstance.searchContacts(.init(query: searchContact)) { contacts, uniqueId, pagination, error in
            if let contacts = contacts{
                withAnimation {
                    self.model.setSearchedContacts(contacts)
                }
            }
        }
    }
    
    func createThread(invitees:[Invitee]){
        Chat.sharedInstance.createThread(.init(invitees: invitees, title: "", type:.NORMAL)) { thread, uniqueId, error in
            if let thread = thread{
                AppState.shared.selectedThread = thread
            }
        }
    }
    
    func loadMore(){
        if !model.hasNext || isLoading || connectionStatus != .CONNECTED{return}
        isLoading = true
        model.preparePaginiation()
        Chat.sharedInstance.getContacts(.init(count:model.count,offset: model.offset)) {[weak self] contacts, uniqueId, pagination, error in
            if let contacts = contacts{
                self?.model.appendContacts(contacts: contacts)
                self?.isLoading = false
            }
        }
    }
    
    func refresh() {
        clear()
        getContacts()
    }
    
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
        model.setupPreview()
    }
    
    func delete(indexSet:IndexSet){
        let contacts = model.contacts.enumerated().filter{indexSet.contains($0.offset)}.map{$0.element}
        delete(contacts)
        contacts.forEach { contact in
            model.reomve(contact)
        }
    }
    
    func delete(_ contacts:[Contact]){
        let contactIds = contacts.compactMap{$0.id}
        Chat.sharedInstance.removeContact(.init(contactIds: contactIds)) { deleted, uniqueId, error in
            if error != nil{
                self.model.appendContacts(contacts: contacts)
            } else if deleted == true{
                self.model.setMaxContactsCountInServer(count: self.model.maxContactsCountInServer - contacts.count)
            }
        }
    }
    
    func toggleSelectedContact(_ contact:Contact, _ isSelected:Bool){
        if isSelected{
            model.addToSelctedContacts(contact)
        }else{
            model.removeToSelctedContacts(contact)
        }
    }

    func deleteSelectedItems(){
        delete(model.selectedContacts)
        model.selectedContacts.forEach { contact in
            model.reomve(contact)
        }
        model.clearSelectedContacts()
    }

    func selectAll(){
        withAnimation {
            isAllSelected = true
            model.contacts.forEach { contact in
                model.addToSelctedContacts(contact)
            }
        }
    }

    func deselectAll(){
        withAnimation {
            isAllSelected = false
            model.contacts.forEach { contact in
                model.removeToSelctedContacts(contact)
            }
        }
    }
    
    func blockOrUnBlock(_ contact:Contact){
        if contact.blocked == false{
            let req = BlockRequest(contactId: contact.id)
            Chat.sharedInstance.blockContact(req) { blockedUser, uniqueId, error in
                if let contact = blockedUser?.contact{
                    self.model.blockOrUnBlock(contact)
                }
            }
        }else {
            let req = UnBlockRequest(contactId: contact.id)
            Chat.sharedInstance.unBlockContact(req) { unblockedUser, uniqueId, error in
                if let contact = unblockedUser?.contact{
                    self.model.blockOrUnBlock(contact)
                }
            }
        }
    }
}
