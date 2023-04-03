//
//  SearchContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/16/21.
//

import Chat
import SwiftUI

struct SearchContactRow: View {
    @EnvironmentObject var contactsVM: ContactsViewModel
    var contact: Contact

    var body: some View {
        HStack {
            ImageLaoderView(url: contact.image ?? contact.user?.image, userName: contact.firstName)
                .id("\(contact.image ?? "")\(contact.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                    .padding(.leading, 4)
                    .lineLimit(1)
                    .font(.headline)
                if let notSeenDuration = ContactRow.getDate(notSeenDuration: contact.notSeenDuration) {
                    Text(notSeenDuration)
                        .padding(.leading, 4)
                        .font(.iransansCaption3)
                        .foregroundColor(Color.gray)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            contactsVM.createThread(invitees: [Invitee(id: "\(contact.id ?? 0)", idType: .contactId)])
        }
    }
}

struct SearchContactRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchContactRow(contact: MockData.contact)
            .environmentObject(ContactsViewModel())
    }
}
