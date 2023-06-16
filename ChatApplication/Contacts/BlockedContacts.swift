//
//  BlockedContacts.swift
//  ChatApplication
//
//  Created by hamed on 6/11/23.
//

import Chat
import ChatAppViewModels
import SwiftUI

struct BlockedContacts: View {
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        List(viewModel.blockedContacts, id: \.blockId) { blocked in
            VStack(alignment: .leading) {
                Text((blocked.nickName ?? blocked.contact?.firstName) ?? "")
                ActionButton(iconSfSymbolName: "hand.raised.slash", iconColor: .red) {
                    ChatManager.activeInstance?.contact.unBlock(.init(blockId: blocked.blockId))
                }
            }
        }
        .navigationTitle(Text("Blocked Contacts"))
        .listStyle(.plain)
    }
}

struct BlockedContacts_Previews: PreviewProvider {
    static var previews: some View {
        BlockedContacts()
    }
}
