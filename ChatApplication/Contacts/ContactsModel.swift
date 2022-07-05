//
//  ContactsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct ContactsModel {
    
    private (set) var count                           = 15
    private (set) var offset                          = 0
    private (set) var maxContactsCountInServer        = 0
    private (set) var hasNext:Bool                    = true
    private (set) var contacts :[Contact]             = []
    private (set) var selectedContacts :[Contact]     = []
    private (set) var searchedContacts:[Contact]      = []
    private (set) var showSearchedContacts            = false
    
    mutating func setHasNext(_ hasNext:Bool){
        self.hasNext = hasNext
    }
    
    mutating func preparePaginiation(){
        offset = contacts.count
    }
    
    mutating func setContacts(contacts:[Contact]?){
        if let contacts = contacts{
            self.contacts = contacts
        }
    }
    
    mutating func appendContacts(contacts:[Contact]){
        self.contacts.append(contentsOf: contacts)
    }
    
    mutating func setMaxContactsCountInServer(count:Int){
        self.maxContactsCountInServer = count
    }
    
    mutating func reomve(_ contact:Contact){
        guard let index = contacts.firstIndex(of:contact)else{return}
        contacts.remove(at: index)
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.contacts   = []
    }
    
    mutating func addToSelctedContacts(_ contact:Contact){
        selectedContacts.append(contact)
    }
    
    mutating func removeToSelctedContacts(_ contact:Contact){
        guard let index = selectedContacts.firstIndex(of: contact) else {return}
        selectedContacts.remove(at: index)
    }
    
    mutating func blockOrUnBlock(_ contact :Contact){
        if let index = contacts.firstIndex(where: {$0.id == contact.id}){
            contacts[index].blocked?.toggle()
        }
    }
    
    mutating func setSearchedContacts(_ contacts:[Contact]){
        self.searchedContacts = contacts
        self.showSearchedContacts = contacts.count > 0
    }
}

extension ContactsModel{
    
    mutating func setupPreview(){
        setContacts(contacts: MockData.generateContacts())
    }
}
