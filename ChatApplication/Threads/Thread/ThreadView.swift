//
//  ThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct ThreadView:View {
    
    @StateObject var viewModel:ThreadViewModel
    
    var body: some View{
        VStack{
            List {
                ForEach(viewModel.model.messages , id:\.id) { message in
                    MessageRow(message: message,viewModel: viewModel)
                        .onAppear {
                            if viewModel.model.messages.last == message{
                                viewModel.loadMore()
                            }
                        }
                        .noSeparators()
                        .listRowBackground(Color.clear)
                }
                .onDelete(perform: { indexSet in
                    print("on delete")
                })
            }
            .background(
                ZStack{
                    Image("chat_bg")
                        .resizable(resizingMode: .tile)
                        .opacity(0.25)
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9),
                                                               Color.blue.opacity(0.6)]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                }
            )
            .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
            }
            .listStyle(PlainListStyle())
            SendContainer(message: "")
        }
        .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
        .navigationBarTitle(Text(viewModel.thread?.title ?? ""), displayMode: .inline)
        .onAppear{
            if let thread = AppState.shared.selectedThread{
                viewModel.setThread(thread: thread)
            }
        }
    }
}

struct SendContainer:View{
    
    @State
    var message:String
    
    
    var body: some View{
        HStack{
            
            Image(systemName: "paperclip")
                .font(.system(size: 24))
                .foregroundColor(Color.gray)
            
            MultilineTextField("Type message here ...",text: $message)
                .cornerRadius(16)
            
            Image(systemName: "mic")
                .font(.system(size: 24))
                .foregroundColor(Color.gray)
            
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.blue)
        }
        .padding(8)
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        ThreadView(viewModel: vm)
            .previewDevice("iPhone 13 Pro Max")
            .onAppear(){
                vm.setupPreview()
            }
    }
}
