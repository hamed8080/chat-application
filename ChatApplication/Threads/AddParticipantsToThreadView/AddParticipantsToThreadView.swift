//
//  AddParticipantsToThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import SwiftUI

struct AddParticipantsToThreadView: View {
    @StateObject var viewModel: AddParticipantsToViewModel
    @EnvironmentObject var contactsVM: ContactsViewModel
    var onCompleted: ([Contact]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        onCompleted(contactsVM.selectedContacts)
                    }
                } label: {
                    Text("Add")
                        .bold()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .ignoresSafeArea()

            List {
                ForEach(contactsVM.contacts) { contact in
                    StartThreadContactRow(isInMultiSelectMode: .constant(true), contact: contact)
                        .onAppear {
                            if contactsVM.contacts.last == contact {
                                contactsVM.loadMore()
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
        .padding(0)
    }
}

struct StartThreadResultModel_Previews: PreviewProvider {
    static var previews: some View {
        AddParticipantsToThreadView(viewModel: .init()) { _ in
        }
        .environmentObject(ContactsViewModel())
        .preferredColorScheme(.dark)
    }
}
