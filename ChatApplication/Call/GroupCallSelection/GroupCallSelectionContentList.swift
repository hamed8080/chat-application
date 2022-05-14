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
                VStack(spacing:0){
                    List {
                        ForEach(contactViewModel.model.contacts , id:\.id) { contact in
                            
                            ContactRow(contact: contact , isInEditMode: $isInEditMode , viewModel: contactViewModel)
                                .noSeparators()
                                .onAppear {
                                    if contactViewModel.model.contacts.last == contact{
                                        viewModel.loadMore()
                                    }
                                }
                            
                        }.onDelete(perform:contactViewModel.delete)
                    }.listStyle(PlainListStyle())
                    
                    
                    HStack{
                        Button(action: {
                            startCallRequest(isVideoCall: false)
                        }, label: {
                            callButton(title: "VOICE", icon: "phone")
                        })
                        
                        Spacer()
                        
                        Button(action: {
                            startCallRequest(isVideoCall: true)
                        }, label: {
                            callButton(title: "VIDEO", icon: "video")
                            
                        })
                    }
                    .padding()
                    .background(Color(named: "text_color_blue").ignoresSafeArea())
                }
            }
            LoadingViewAt(isLoading:contactViewModel.isLoading ,reader:reader)
        }
        .navigationBarTitle(Text("Select Contacts"), displayMode: .inline)
    }
    
    @ViewBuilder
    func callButton(title:String, icon:String)->some View{
        HStack{
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(.white)
            
            Text(title.uppercased())
                .foregroundColor(.white)
                .font(.system(size: 16).bold())
        }
    }
    
    func startCallRequest(isVideoCall:Bool){
        callState.model.setIsVideoCallRequest(isVideoCall)
        callState.model.setIsP2PCalling(false)
        callState.model.setSelectedContacts(contactViewModel.model.selectedContacts)
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
