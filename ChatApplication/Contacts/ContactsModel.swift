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
    private (set) var totalCount                      = 0
    private (set) var contacts :[Contact]             = []
    private (set) var selectedContacts :[Contact]     = []
        
    func hasNext()->Bool{
        return contacts.count < totalCount
    }
    
    mutating func preparePaginiation(){
        offset = contacts.count
    }
    
    mutating func setContentCount(totalCount:Int){
        self.totalCount = totalCount
    }
    
    mutating func setContacts(contacts:[Contact]? , totalCount:Int ){
        if let contacts = contacts{
            self.contacts = contacts
            setContentCount(totalCount:totalCount)
        }
    }
    
    mutating func appendContacts(contacts:[Contact]){
        self.contacts.append(contentsOf: contacts)
    }
    
    mutating func reomve(_ contact:Contact){
        guard let index = contacts.firstIndex(of:contact)else{return}
        contacts.remove(at: index)
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.totalCount = 0
        self.contacts   = []
    }
    
    mutating func addToSelctedContacts(_ contact:Contact){
        selectedContacts.append(contact)
    }
    
    mutating func removeToSelctedContacts(_ contact:Contact){
        guard let index = selectedContacts.firstIndex(of: contact) else {return}
        selectedContacts.remove(at: index)
    }
}

extension ContactsModel{
    
    mutating func setupPreview(){
        let t1 = ContactRow_Previews.contact
        t1.firstName = "Hamed"
        t1.lastName  =  "Hosseini23232"
        t1.id = 1
        
        let t2 = ContactRow_Previews.contact
        t2.firstName = "Masoud"
        t2.lastName = "Amjadi"
        t2.id = 2
        
        let t3 = ContactRow_Previews.contact
        t2.firstName = "Pod Group"
        t3.id = 3
        let contacts = [t1 , t2, t3] + [t1 , t2, t3] + [t1 , t2, t3] +  [t1 , t2, t3]
        appendContacts(contacts: contacts)
    }
}
