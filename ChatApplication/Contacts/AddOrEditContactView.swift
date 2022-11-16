//
//  AddOrEditContactView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/23/21.
//

import FanapPodChatSDK
import SwiftUI

struct AddOrEditContactView: View {
    @State
    var contactValue: String = ""

    @State
    var firstName: String = ""

    @State
    var lastName: String = ""

    @Environment(\.presentationMode)
    var presentationMode

    @Environment(\.horizontalSizeClass)
    var sizeClass

    @EnvironmentObject
    var contactsVM: ContactsViewModel

    var title: String { contactsVM.isInEditMode ? "Edit Contact" : "Add Contact"  }

    var body: some View {
        VStack(spacing: 24) {
            PrimaryTextField(title: "type contact", textBinding: $contactValue, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.1))
            PrimaryTextField(title: "first name", textBinding: $firstName, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.1))
            PrimaryTextField(title: "last name", textBinding: $lastName, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.1))

            Button(action: {
                let isPhone = validatePhone(value: contactValue)
                let req: AddContactRequest = isPhone ?
                    .init(cellphoneNumber: contactValue, email: nil, firstName: firstName, lastName: lastName, ownerId: nil, uniqueId: nil) :
                    .init(email: nil, firstName: firstName, lastName: lastName, ownerId: nil, username: contactValue, uniqueId: nil)
                Chat.sharedInstance.addContact(req) { contacts, _, _ in
                    if let contacts = contacts {
                        contactsVM.insertContactsAtTop(contacts)
                    }
                    self.presentationMode.wrappedValue.dismiss()
                }
            }, label: {
                Text("Submit")
            })
            .buttonStyle(PrimaryButtonStyle())
            Spacer()
        }
        .navigationTitle(title)
        .padding(.top)
        .padding([.leading, .trailing], sizeClass == .compact ? 16 : 128)
    }

    func validatePhone(value: String) -> Bool {
        let PHONE_REGEX = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let result = phoneTest.evaluate(with: value)
        return result
    }
}

struct AddOrEditContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddOrEditContactView()
    }
}
