//
//  SearchContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/16/21.
//

import FanapPodChatSDK
import SwiftUI

struct SearchContactRow: View {
    @EnvironmentObject var contactVM: ContactViewModel
    var contact: Contact { contactVM.contact }

    var body: some View {
        HStack {
            contactVM.imageLoader.imageView
                .font(.system(size: 16).weight(.heavy))
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
                        .font(.headline.weight(.medium))
                        .foregroundColor(Color.gray)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: .infinity, height: 1)
            }
        }
        .contentShape(Rectangle())
        .autoNavigateToThread()
        .onTapGesture {
            contactVM.contactsVM?.createThread(invitees: [Invitee(id: "\(contact.id ?? 0)", idType: .contactId)])
        }
    }
}

struct SearchContactRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchContactRow()
            .environmentObject(ContactViewModel(contact: MockData.contact, contactsVM: ContactsViewModel()))
    }
}
