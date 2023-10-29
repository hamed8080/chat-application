//
//  AddOrEditContactView.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Chat
import ChatModels
import SwiftUI
import TalkViewModels
import TalkUI

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
    var editContact: Contact? { viewModel.editContact }
    @FocusState var focusState: ContactFocusFileds?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !isLargeSize{
                Spacer()
            }
            Text(editContact != nil ? "Contacts.Edit.title" : "Contacts.Add.title")
                .font(.iransansBoldSubtitle)
                .padding()
                .offset(y: 24)
            TextField("General.firstName", text: $firstName)
                .focused($focusState, equals: .firstName)
                .textContentType(.name)
                .padding()
                .applyAppTextfieldStyle(topPlaceholder: "General.firstName", isFocused: focusState == .firstName) {
                    focusState = .firstName
                }
            TextField(optioanlAPpend(text: "General.lastName"), text: $lastName)
                .focused($focusState, equals: .lastName)
                .textContentType(.familyName)
                .padding()
                .applyAppTextfieldStyle(topPlaceholder: "General.lastName", isFocused: focusState == .lastName) {
                    focusState = .lastName
                }
            TextField("Contacts.Add.phoneOrUserName", text: $contactValue)
                .focused($focusState, equals: .contactValue)
                .keyboardType(.default)
                .padding()
                .applyAppTextfieldStyle(topPlaceholder: "Contacts.Add.phoneOrUserName", isFocused: focusState == .contactValue) {
                    focusState = .contactValue
                }
            if isLargeSize {
                Spacer()
            }
            let title = editContact != nil ? "Contacts.Edit.title" : "Contacts.Add.title"
            SubmitBottomButton(text: title, enableButton: .constant(enableButton), isLoading: .constant(false)) {
                submit()
            }
        }
        .presentationDetents([.fraction((isLargeSize ? 100 : 60) / 100)])
        .presentationBackground(.ultraThinMaterial)
        .presentationDragIndicator(.visible)
//        .background(bgColor)
        .animation(.easeInOut, value: enableButton)
        .animation(.easeInOut, value: focusState)
        .font(.iransansBody)
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            firstName = editContact?.firstName ?? ""
            lastName = editContact?.lastName ?? ""
            contactValue = editContact?.computedUserIdentifire ?? ""
            focusState = .firstName
        }
        .onDisappear {
            /// Clearing the view for when the user cancels the sheet by dropping it down.
            viewModel.showAddOrEditContactSheet = false
            viewModel.editContact = nil
        }
    }

    private var isLargeSize: Bool {
        let mode = UIApplication.shared.windowMode()
        if mode == .ipadFullScreen || mode == .ipadHalfSplitView || mode == .ipadTwoThirdSplitView {
            return true
        } else {
            return false
        }
    }

    private var enableButton: Bool {
        !firstName.isEmpty && !contactValue.isEmpty
    }

    func submit() {
        if let editContact = editContact {
            viewModel.updateContact(contact: editContact, contactValue: contactValue, firstName: firstName, lastName: lastName)
        } else {
            viewModel.addContact(contactValue: contactValue, firstName: firstName, lastName: lastName)
        }
        viewModel.editContact = nil
        viewModel.showAddOrEditContactSheet = false
        dismiss()
    }

    func optioanlAPpend(text: String) -> String {
        "\(String(localized: .init(text))) \(String(localized: "General.optional"))"
    }
}

struct AddOrEditContactView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddOrEditContactView()
                .environmentObject(ContactsViewModel())
        }
    }
}
