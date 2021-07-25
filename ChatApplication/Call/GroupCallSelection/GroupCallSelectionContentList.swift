//
//  GroupCallSelectionContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct GroupCallSelectionContentList: View {
    
    @StateObject
    var viewModel           :CallsHistoryViewModel
    
    @State var isInEditMode : Bool             = true
    
    @StateObject
    var contactViewModel    :ContactsViewModel = ContactsViewModel()
    
    @EnvironmentObject
    var callState:CallState
        
    var body: some View {
        GeometryReader{ reader in
            ZStack{
                List {
                    ForEach(contactViewModel.model.contacts , id:\.id) { contact in
                        
                        ContactRow(contact: contact , isInEditMode: $isInEditMode , viewModel: contactViewModel)
                            .onAppear {
                                if contactViewModel.model.contacts.last == contact{
                                    viewModel.loadMore()
                                }
                            }
                        
                    }.onDelete(perform:contactViewModel.delete)
                }.listStyle(PlainListStyle())
                
                VStack{
                    Spacer()
                    Button(action: {
                        callState.isP2PCalling = false
                        callState.selectedContacts = contactViewModel.model.selectedContacts
                        callState.showCallView.toggle()
                    }, label: {
                        HStack{
                            Text("Start Group Call".uppercased())
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .fontWeight(.heavy)
                            Image(systemName: "phone")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                
                        }
                    })
                    .frame(width: reader.size.width, height: 48)
                    .background(Color.blue)
                }
            }
            LoadingViewAtBottomOfView(isLoading:contactViewModel.isLoading ,reader:reader)
        }
        .navigationBarTitle(Text("Select Contacts"), displayMode: .inline)
    }
}



struct GroupCallSelectionContentListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CallsHistoryViewModel()
        GroupCallSelectionContentList(viewModel:viewModel)
            .onAppear(){
                viewModel.setupPreview()
            }
    }
}
