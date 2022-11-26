//
//  ContactViewModel.swift
//  ChatApplication
//
//  Created by hamed on 11/26/22.
//

import Foundation
import Combine
import FanapPodChatSDK

protocol ContactViewModelProtocol {
    var contact: Contact { get set }
    var contactId: Int? { get }
    var isSelected: Bool { get set }
    var contactsVM: ContactsViewModel { get set }
    init(contact: Contact, contactsVM: ContactsViewModel)
    func blockOrUnBlock(_ contact: Contact)
    func onBlockUNBlockResponse(_ contact: BlockedContact?, _ uniqueId: String?, _ error: ChatError?)
    func toggleSelectedContact()
    func updateContact(contactValue: String, firstName: String?, lastName: String?)
}

class ContactViewModel: ObservableObject, ContactViewModelProtocol, Identifiable, Hashable {
    var contactsVM: ContactsViewModel

    @Published
    var contact: Contact

    var contactId: Int? { contact.id }

    @Published
    var isSelected = false

    static func == (lhs: ContactViewModel, rhs: ContactViewModel) -> Bool {
        rhs.contactId == lhs.contactId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(contactId)
    }

    required init(contact: Contact, contactsVM: ContactsViewModel) {
        self.contactsVM = contactsVM
        self.contact = contact
    }

    func blockOrUnBlock(_ contact: Contact) {
        if contact.blocked == false {
            let req = BlockRequest(contactId: contact.id)
            Chat.sharedInstance.blockContact(req, completion: onBlockUNBlockResponse)
        } else {
            let req = UnBlockRequest(contactId: contact.id)
            Chat.sharedInstance.unBlockContact(req, completion: onBlockUNBlockResponse)
        }
    }

    func onBlockUNBlockResponse(_ contact: BlockedContact?, _ uniqueId: String?, _ error: ChatError?) {
        if contact != nil {
            self.contact.blocked?.toggle()
            objectWillChange.send()
        }
    }

    func toggleSelectedContact() {
        isSelected.toggle()
        if isSelected {
            contactsVM.addToSelctedContacts(contact)
        } else {
            contactsVM.removeToSelctedContacts(contact)
        }
    }

    func updateContact(contactValue: String, firstName: String?, lastName: String?) {
        guard let contactId = contactId else { return }
        let req: UpdateContactRequest = .init(cellphoneNumber: contactValue, email: contact.email ?? "", firstName: firstName ?? "", id: contactId, lastName: lastName ?? "", username: contact.linkedUser?.username ?? "")
        Chat.sharedInstance.updateContact(req) { [weak self] contacts, _, _ in
            contacts?.forEach{ updatedContact in
                if updatedContact.id == contactId {
                    self?.contact.update(updatedContact)
                    self?.objectWillChange.send()
                }
            }
        }
    }
}
