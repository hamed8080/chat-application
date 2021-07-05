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
    
    @State
    var navigateToGroupCallSelction = false
    
    var body: some View {
        NavigationView{
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
                    }.listStyle(PlainListStyle())
                    VStack{
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
                    }
                    .frame(width: 64, height: 64)
                    .position(x: reader.size.width - 48, y: reader.size.height - reader.safeAreaInsets.bottom)
                }
                LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
                
                NavigationLink(
                    destination: GroupCallSelectionContentList(viewModel: viewModel),
                    isActive: $navigateToGroupCallSelction){
                    EmptyView()
                }
            }
            .navigationBarTitle(Text("Calls"), displayMode: .inline)
            .toolbar{
                ToolbarItem(placement:.navigationBarLeading){
                    Text(viewModel.model.connectionStatus ?? "")
                        .font(.headline)
                        .foregroundColor(Color.gray)
                }
            }
        }
    }
}



struct CallsHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CallsHistoryViewModel()
        CallsHistoryContentList(viewModel:viewModel)
            .onAppear(){
                viewModel.setupPreview()
            }
    }
}
