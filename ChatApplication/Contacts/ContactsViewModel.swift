//
//  ContactsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine

class ContactsViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    private (set) var model = ContactsModel()
    
    @Published
    public var isInEditMode                    = false
    
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
            }            
            self.connectionStatus = status
        }
        getOfflineContacts()
    }
    
    func getContacts() {
        Chat.sharedInstance.getContacts(.init(count:model.count,offset: model.offset)) { [weak self] contacts, uniqueId, pagination, error in
            if let contacts = contacts{
                self?.isFirstTimeConnectedRequestSuccess = true
                self?.model.setHasNext(pagination?.hasNext ?? false)
                self?.model.setContacts(contacts: contacts)
                self?.model.setMaxContactsCountInServer(count: (pagination as? PaginationWithContentCount)?.totalCount ?? 0)
            }
        }
    }
    
    func getOfflineContacts() {
        let req = ContactsRequest(count:model.count,offset: model.offset)
        CacheFactory.get(useCache: true, cacheType: .GET_CASHED_CONTACTS(req)) { response in
            let contacts = response.cacheResponse as? [Contact]
            self.model.setContacts(contacts: contacts)
            self.model.setMaxContactsCountInServer(count: CMContact.crud.getTotalCount())
        }
    }
    
    func searchContact(_ searchContact:String){
        if searchContact.count <= 0{
            self.model.setSearchedContacts([])
            return
        }
        Chat.sharedInstance.searchContacts(.init(query: searchContact)) { contacts, uniqueId, pagination, error in
            if let contacts = contacts{
                self.model.setSearchedContacts(contacts)                
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
        contacts.forEach { contact in
            delete(contact)
            model.reomve(contact)
        }
    }
    
    func delete(_ contact:Contact){
        if let contactId = contact.id{
            Chat.sharedInstance.removeContact(.init(contactId: contactId)) { deleted, uniqueId, error in
                if error != nil{
                    self.model.appendContacts(contacts: [contact])
                }
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
        model.selectedContacts.forEach { contact in
            model.reomve(contact)
            delete(contact)
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
