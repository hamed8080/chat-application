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
    
    @EnvironmentObject var appState :AppState
    
    var body: some View{
        GeometryReader{ reader in
                List{
                    ForEach(viewModel.model.contacts , id:\.id) { contact in
                        ContactRow(contact: contact , isInEditMode: $viewModel.isInEditMode , viewModel: viewModel)
                            .noSeparators()
                            .onAppear {
                                if viewModel.model.contacts.last == contact{
                                    viewModel.loadMore()
                                }
                            }
                            .animation(.default)
                    }
                    .onDelete(perform:viewModel.delete)
                    .padding(0)
                }
                .padding(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
                .listStyle(PlainListStyle())
            
            LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
            NavigationLink(destination: AddOrEditContactView(), isActive: $viewModel.navigateToAddOrEditContact){
                EmptyView()
            }
        }     
    }
}

struct ContactContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ContactsViewModel()
        
        ContactContentList(viewModel: vm)
//            .previewDevice("iPhone 12 Pro Max")
            .onAppear(){
                vm.setupPreview()
            }
            .environmentObject(AppState.shared)
    }
}
