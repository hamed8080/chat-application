//
//  ContactRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ContactRow: View {
    @Binding public var isInSelectionMode: Bool
    @EnvironmentObject var viewModel: ContactsViewModel
    @EnvironmentObject var appState: AppState
    var contact: Contact
    var contactImageURL: String? { contact.image ?? contact.user?.image }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: contact.image ?? contact.user?.image, userName: contact.firstName)
                    .id("\(contact.image ?? "")\(contact.id ?? 0)")
                    .font(.iransansBody)
                    .foregroundColor(Color.App.text)
                    .frame(width: 52, height: 52)
                    .background(Color.App.blue.opacity(0.4))
                    .cornerRadius(22)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                        .padding(.leading, 16)
                        .lineLimit(1)
                        .font(.iransansBoldBody)
                        .foregroundColor(Color.App.text)
                    if let notSeenDuration = contact.notSeenString {
                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"))
                        let time = String(format: lastVisitedLabel, notSeenDuration)
                        Text(time)
                            .padding(.leading, 16)
                            .font(.iransansBody)
                            .foregroundColor(Color.App.hint)
                    }
                }
                Spacer()
                if contact.blocked == true {
                    Text("General.blocked")
                        .font(.iransansCaption2)
                        .foregroundColor(Color.App.red)
                        .padding(.trailing, 4)
                }
                selectRadio
            }
        }
        .animation(.easeInOut, value: contact.blocked)
        .animation(.easeInOut, value: contact)
    }

    @ViewBuilder var selectRadio: some View {
        let isSelected = viewModel.isSelected(contact: contact)
        RadioButton(visible: $isInSelectionMode, isSelected: .constant(isSelected)) { isSelected in
            viewModel.toggleSelectedContact(contact: contact)
        }
    }
}

struct ContactRow_Previews: PreviewProvider {
    @State static var isInSelectionMode = false

    static var previews: some View {
        Group {
            ContactRow(isInSelectionMode: $isInSelectionMode, contact: MockData.contact)
                .environmentObject(ContactsViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
