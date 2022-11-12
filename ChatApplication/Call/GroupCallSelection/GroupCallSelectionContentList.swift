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
    
    @State
    var groupTitle :String = ""
    
    var body: some View {
        GeometryReader{ reader in
            ZStack{
                VStack(spacing:0){
                    List {
                        MultilineTextField("Group Name ...",text: $groupTitle, backgroundColor:Color.gray.opacity(0.2)){submit in
                            hideKeyboard()
                        }
                        .cornerRadius(16)
                        .noSeparators()
                        .onChange(of: groupTitle) { newValue in
                            callState.model.setGroupName(name: newValue)
                        }
                        
                        ForEach(contactViewModel.contacts , id:\.id) { contact in
                            
                            ContactRow(contact: contact , isInEditMode: $isInEditMode)
                                .noSeparators()
                                .onAppear {
                                    if contactViewModel.contacts.last == contact{
                                        viewModel.loadMore()
                                    }
                                }
                        }
                        .onDelete(perform:contactViewModel.delete)
                    }
                    .listStyle(.plain)
                }
                
                VStack{
                    GeometryReader{ reader in
                        LoadingViewAt(isLoading:viewModel.isLoading, reader: reader)
                    }
                }
            }
        }
        .navigationBarTitle(Text("Select Contacts"), displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    startCallRequest(isVideoCall: true)
                } label: {
                    Label {
                        Text("VIDEO")
                    } icon: {
                        Image(systemName: "video.fill")
                    }
                }
                
                Button {
                    startCallRequest(isVideoCall: false)
                } label: {
                    Label {
                        Text("VOICE")
                    } icon: {
                        Image(systemName: "phone.fill")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func callButton(title:String, icon:String)->some View{
        HStack{
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            
            Text(title.uppercased())
                .font(.system(size: 16).bold())
        }
    }
    
    func startCallRequest(isVideoCall:Bool){
        if groupTitle.isEmpty{
            callState.model.setGroupName(name: "group")
        }
        callState.model.setIsVideoCallRequest(isVideoCall)
        callState.model.setIsP2PCalling(false)
        callState.model.setSelectedContacts(contactViewModel.selectedContacts)
        callState.model.setShowCallView(true)
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
