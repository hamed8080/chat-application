//
//  ContactContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct ContactContentList:View {
    
    @StateObject var viewModel :ContactsViewModel
    
    @State var isInEditMode             = false
    
    var body: some View{
        NavigationView{
            GeometryReader{ reader in
                List {
                    ForEach(viewModel.model.contacts , id:\.id) { contact in
                        
                        ContactRow(contact: contact , isInEditMode: $isInEditMode , viewModel: viewModel)
                            .onAppear {
                                if viewModel.model.contacts.last == contact{
                                    viewModel.loadMore()
                                }
                            }
                        
                    }.onDelete(perform:viewModel.delete)
                }.listStyle(PlainListStyle())
                LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
            }
            .navigationBarTitle(Text("Contacts"), displayMode: .inline)
            .toolbar(){
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit"){
                        withAnimation {
                            isInEditMode.toggle()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isInEditMode == true{
                        Button("Delete"){
                            withAnimation {
                                viewModel.deleteSelectedItems()
                            }
                        }
                    }
                }
                
            }
            
        }
    }
}

struct ContactContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ContactsViewModel()
        
        ContactContentList(viewModel: vm)
            .onAppear(){
                vm.setupPreview()
            }
    }
}
