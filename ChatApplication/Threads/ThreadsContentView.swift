//
//  ThreadsContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct ThreadsContentView: View {
    
    @StateObject
    private var viewModel = ThreadsViewModel()
    
    @State var isAnimating          = false
    @State var isAnimatingLoadMore  = false
    
    var body: some View {
        GeometryReader{ reader in
            VStack{
                if viewModel.model.threads.count == 0{
                    LoadingView(isAnimating: $isAnimating)
                        .frame(width: 48, height: 48, alignment: .center)
                        .position(x: reader.size.width / 2, y: reader.size.height / 2)
                        .onAppear{
                            isAnimating.toggle()
                        }
                }else{
                    Spacer()
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.model.threads , id:\.id) { thread in
                                ThreadRow(thread: thread)
                                    .frame(width: reader.size.width - 16, alignment: .leading)
                                    .padding(8)
                                    .onAppear {
                                        if viewModel.model.threads.last == thread{
                                            viewModel.loadMore()
                                        }
                                    }
                            }
                        }
                    }
                }
                if viewModel.isLoading{
                    LoadingView(isAnimating: $isAnimatingLoadMore,width: 2)
                        .frame(width: 24, height: 24, alignment: .center)
                        .onAppear{
                            isAnimatingLoadMore = true
                        }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadsContentView()
    }
}
