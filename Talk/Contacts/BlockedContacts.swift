//
//  BlockedContacts.swift
//  Talk
//
//  Created by hamed on 6/11/23.
//

import Chat
import SwiftUI
import TalkViewModels
import TalkUI

struct BlockedContacts: View {
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        List(viewModel.blockedContacts, id: \.blockId) { blocked in
            HStack {
                let contactName = blocked.contact?.user?.name ?? blocked.contact?.firstName
                let name = blocked.nickName ?? contactName
                let userId = blocked.contact?.cellphoneNumber ?? blocked.contact?.email ?? "\(blocked.coreUserId ?? 0)"

                ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: blocked.profileImage ?? blocked.contact?.image, userName: name)
                    .id(userId)
                    .font(.iransansBody)
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.App.blue.opacity(0.4))
                    .cornerRadius(22)

                VStack(alignment: .leading) {
                    Text(name ?? "")
                        .foregroundStyle(Color.App.text)
                        .font(.iransansBoldBody)

                    Text(userId)
                        .font(.caption2)
                        .foregroundStyle(Color.App.hint)
                }

                Spacer()
                Button {
                    if let blockedId = blocked.blockId {
                        viewModel.unblock(blockedId)
                    }
                } label: {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(blocked.blockId == viewModel.blockedContacts.last?.blockId ? Color.clear : Color.App.divider)
        }
        .background(Color.App.bgPrimary)
        .navigationTitle("Contacts.blockedList")
        .navigationBarBackButtonHidden(true)
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: BlockedContactsNavigationValue.self)
                }
            }
        }
    }
}

struct BlockedContacts_Previews: PreviewProvider {
    static var previews: some View {
        BlockedContacts()
    }
}
