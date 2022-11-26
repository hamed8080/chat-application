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

    @Environment(\.dismiss)
    var dismiss

    @EnvironmentObject
    var viewModel: ContactViewModel

    @EnvironmentObject
    var contactsViewModel: ContactsViewModel
    var editContact: Contact? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                PrimaryTextField(title: "type contact", textBinding: $contactValue, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.1))
                PrimaryTextField(title: "first name", textBinding: $firstName, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.1))
                PrimaryTextField(title: "last name", textBinding: $lastName, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.1))
                Button(action: {
                    if editContact != nil {
                        viewModel.updateContact(contactValue: contactValue, firstName: firstName, lastName: lastName)
                    } else {
                        contactsViewModel.addContact(contactValue: contactValue, firstName: firstName, lastName: lastName)
                    }
                    dismiss()
                }, label: {
                    Text("Submit")
                })
                .buttonStyle(PrimaryButtonStyle())
                Spacer()
            }
            .navigationTitle("\(editContact != nil ? "Edit" : "Add") Contact")
            .padding(.all, 48)
            .onAppear {
                firstName = editContact?.firstName ?? ""
                lastName = editContact?.lastName ?? ""
                contactValue = editContact?.cellphoneNumber ?? editContact?.email ?? editContact?.linkedUser?.username ?? ""
            }
        }
    }
}

struct AddOrEditContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddOrEditContactView()
    }
}
