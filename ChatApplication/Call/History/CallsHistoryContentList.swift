//
//  CallsHistoryContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct CallsHistoryContentList: View {
    
    @StateObject
    var viewModel:CallsHistoryViewModel
    
    @EnvironmentObject var appState:AppState
    
    @State
    var navigateToGroupCallSelction = false
        
    var body: some View {
        GeometryReader{ reader in
                ZStack{
                    List {
                        ForEach(viewModel.model.calls , id:\.id) { call in
                            CallRow(call: call,viewModel: viewModel)
                                .frame(minHeight:64)
                                .onAppear {
                                    if viewModel.model.calls.last == call{
                                        viewModel.loadMore()
                                    }
                                }
                        }.onDelete(perform: { indexSet in
                            print("on delete")
                        })
                    }
                    .padding(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
                    .listStyle(PlainListStyle())
                    Button(action: {
                        navigateToGroupCallSelction.toggle()
                    }, label: {
                        Circle()
                            .fill(Color.blue)
                            .shadow(color: .blue, radius: 20, x: 0, y: 0)
                            .overlay(
                                Image(systemName:"person.3.fill")
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .padding(16)
                            )
                        
                    })
                    .frame(width: 64, height: 64)
                    .position(x: reader.size.width - 48, y: reader.size.height - (reader.safeAreaInsets.bottom  + 24))
                }
                LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
                
                NavigationLink(
                    destination: GroupCallSelectionContentList(viewModel: viewModel),
                    isActive: $navigateToGroupCallSelction){
                    EmptyView()
                }
            }
    }
}

struct CallsHistoryContentList_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CallsHistoryViewModel()
        CallsHistoryContentList(viewModel:viewModel)
            .environmentObject(AppState.shared)
            .environmentObject(CallState.shared)
            .onAppear(){
                viewModel.setupPreview()
            }
    }
}
