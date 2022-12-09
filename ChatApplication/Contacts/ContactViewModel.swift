//
//  ContactViewModel.swift
//  ChatApplication
//
//  Created by hamed on 11/26/22.
//

import Combine
import FanapPodChatSDK
import Foundation

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
    @Published var isSelected = false
    @Published var imageLoader: ImageLoader
    @Published var contact: Contact
    var contactsVM: ContactsViewModel
    var contactId: Int? { contact.id }
    var cancellableSet: Set<AnyCancellable> = []

    static func == (lhs: ContactViewModel, rhs: ContactViewModel) -> Bool {
        rhs.contactId == lhs.contactId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(contactId)
    }

    required init(contact: Contact, contactsVM: ContactsViewModel) {
        self.contactsVM = contactsVM
        self.contact = contact
        imageLoader = ImageLoader(url: contact.image ?? contact.linkedUser?.image ?? "", userName: contact.firstName, size: .SMALL)
        imageLoader.$image.sink { _ in
            self.objectWillChange.send()
        }
        .store(in: &cancellableSet)
        imageLoader.fetch()
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

    func onBlockUNBlockResponse(_ contact: BlockedContact?, _: String?, _: ChatError?) {
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
            contacts?.forEach { updatedContact in
                if updatedContact.id == contactId {
                    self?.contact.update(updatedContact)
                    self?.objectWillChange.send()
                }
            }
        }
    }
}
