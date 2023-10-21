//
//  SearchContactRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 11/16/21.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct SearchContactRow: View {
    @EnvironmentObject var contactsVM: ContactsViewModel
    var contact: Contact

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: contact.image ?? contact.user?.image, userName: contact.firstName)
                .id("\(contact.image ?? "")\(contact.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(20)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                    .padding(.leading, 4)
                    .lineLimit(1)
                    .font(.iransansCaption)
                if let notSeenDuration = contact.notSeenString {
                    let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"))
                    let time = String(format: lastVisitedLabel, notSeenDuration)
                    Text(time)
                        .padding(.leading, 4)
                        .font(.iransansCaption3)
                        .foregroundColor(Color.gray)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            AppState.shared.openThread(contact: contact)
        }
    }
}

struct SearchContactRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchContactRow(contact: MockData.contact)
            .environmentObject(ContactsViewModel())
    }
}
