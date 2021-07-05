//
//  ContactsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

class ContactsViewModel:ObservableObject{
    
    var isLoading = false
    
    @Published
    private (set) var model = ContactsModel()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionStatusChanged(_:)), name: CONNECTION_STATUS_NAME_OBJECT, object: nil)
        if ChatDelegateImplementation.lastConnectionStatus == .CONNECTED{
            getContacts()
        }
    }
    
    @objc private func onConnectionStatusChanged(_ notification:NSNotification){
        if let connectionStatus = notification.object as? ConnectionStatus{
            if model.contacts.count == 0 && connectionStatus == .CONNECTED {
                getContacts()
            }
        }
    }
    
    func getContacts() {
        Chat.sharedInstance.getContacts(.init(count:model.count,offset: model.offset)) { [weak self] contacts, uniqueId, pagination, error in
            self?.model.setContacts(contacts: contacts, totalCount: pagination?.totalCount ?? 0)
        } cacheResponse: { [weak self] contacts, uniqueId, pagination, error in
            self?.model.setContacts(contacts: contacts, totalCount: pagination?.totalCount ?? 0)
        }
    }
    
    func loadMore(){
        if !model.hasNext() || isLoading{return}
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
    
}
