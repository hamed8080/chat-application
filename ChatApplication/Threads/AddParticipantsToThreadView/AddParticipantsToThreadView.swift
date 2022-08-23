//
//  AddParticipantsToThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct AddParticipantsToThreadView:View {

    @StateObject
    var viewModel:AddParticipantsToViewModel

    @StateObject
    var contactsVM = ContactsViewModel()

    @EnvironmentObject var appState:AppState

    var onCompleted:([Contact])->()

    var body: some View{
        VStack(alignment:.leading,spacing: 0){
            HStack{
                Spacer()
                Button {
                    withAnimation {
                        onCompleted(contactsVM.model.selectedContacts)
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
                ForEach(contactsVM.model.contacts , id:\.id) { contact in
                    StartThreadContactRow(contact: contact, isInMultiSelectMode: .constant(true), viewModel: contactsVM)
                        .onAppear {
                            if contactsVM.model.contacts.last == contact{
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
        let appState = AppState.shared
        let vm = StartThreadContactPickerViewModel()
        let contactVM = ContactsViewModel()
        AddParticipantsToThreadView(viewModel: .init(),
                                    contactsVM: contactVM)
        { contacts in

        }
        .preferredColorScheme(.dark)
        .onAppear(){
            vm.setupPreview()
            contactVM.setupPreview()
        }
        .environmentObject(appState)
    }
}
