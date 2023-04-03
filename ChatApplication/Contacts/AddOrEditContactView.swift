//
//  AddOrEditContactView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Chat
import SwiftUI

enum ContactType: String, Identifiable, CaseIterable {
    var id: Self { self }
    case phoneNumber
    case userName
}

enum ContactFocusFileds: Hashable {
    case contactValue
    case firstName
    case lastName
    case submit
}

struct AddOrEditContactView: View {
    @State var contactValue: String = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ContactsViewModel
    @EnvironmentObject var contactsViewModel: ContactsViewModel
    var editContact: Contact?
    @FocusState var focusState: ContactFocusFileds?
    @State var contactType: ContactType = .phoneNumber

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("ContactType", selection: $contactType) {
                        ForEach(ContactType.allCases) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    TextField("Contact", text: $contactValue)
                        .focused($focusState, equals: .contactValue)
                        .keyboardType(contactType == .phoneNumber ? .phonePad : .default)
                    TextField("First Name", text: $firstName)
                        .focused($focusState, equals: .firstName)
                        .textContentType(.name)
                    TextField("Last Name", text: $lastName)
                        .focused($focusState, equals: .lastName)
                        .textContentType(.familyName)
                } header: {
                    Text("General Information")
                } footer: {
                    Text("In the Contact filed you could enter either username or phone number.")
                }
            }
            .headerProminence(.increased)
            .navigationTitle("\(editContact != nil ? "Edit" : "Add") Contact")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        submit()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                firstName = editContact?.firstName ?? ""
                lastName = editContact?.lastName ?? ""
                contactValue = editContact?.computedUserIdentifire ?? ""
            }
        }
    }

    func submit() {
        if let editContact = editContact {
            viewModel.updateContact(contact: editContact, contactValue: contactValue, firstName: firstName, lastName: lastName)
        } else {
            contactsViewModel.addContact(contactValue: contactValue, firstName: firstName, lastName: lastName)
        }
        dismiss()
    }
}

struct AddOrEditContactView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddOrEditContactView()
        }
    }
}
