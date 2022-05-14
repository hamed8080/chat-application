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
            VStack(spacing:0){
                CustomNavigationBar(title: "Calls")
                ZStack{
                    List {
                        ForEach(viewModel.model.calls , id:\.id) { call in
                            NavigationLink(destination: CallDetails(viewModel: .init(call: call))){
                                CallRow(call: call,viewModel: viewModel)
                                    .frame(minHeight:64)
                                    .onAppear {
                                        if viewModel.model.calls.last == call{
                                            viewModel.loadMore()
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
                    .listStyle(PlainListStyle())
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Button {
                                navigateToGroupCallSelction.toggle()
                            } label: {
                                Image(systemName:"video.fill")
                                    .scaledToFit()
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(
                                DeepButtonStyle(
                                    frame: .init(width: 52, height: 52),
                                    backgroundColor: Color(named: "text_color_blue"),
                                    shadow: 2,
                                    cornerRadius: 48
                                )
                            )
                        }
                        .padding([.trailing, .bottom], 8)
                    }
                }
                LoadingViewAt(isLoading:viewModel.isLoading ,reader:reader)
            }
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
