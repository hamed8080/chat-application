//
//  ThreadDetailView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK
import Photos

struct ThreadDetailView:View {
    
    @StateObject
    var viewModel:ThreadViewModel
    
    @State
    var threadTitle:String = ""
    
    @State
    var threadDescription:String = ""
    
    @State
    var isInEditMode = false
    
    @State
    var showImagePicker:Bool = false
    
    @State private var image: UIImage?
    @State private var assetResource: [PHAssetResource]?
    
    var body: some View{
        
        let thread = viewModel.model.thread
        
        GeometryReader{ reader in
            VStack{
                List{
                    VStack{
                        Avatar(url: thread?.image, userName: thread?.title?.uppercased() ,fileMetaData:thread?.metadata,style: .init(size: 128 ,textSize: 48))
                            .onTapGesture {
                                if isInEditMode{
                                    showImagePicker = true
                                }
                            }
                        
                        PrimaryTextField(title:"Title", textBinding: $threadTitle, keyboardType: .alphabet, backgroundColor: Color.primary.opacity(0.08))
                        .disabled(!isInEditMode)
                        .multilineTextAlignment(.center)
                        .font(.headline.bold())
                        
                        PrimaryTextField(title:"Description", textBinding: $threadDescription, keyboardType: .alphabet,backgroundColor: Color.primary.opacity(0.08))
                        .disabled(!isInEditMode)
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        
                        if let lastSeen = ContactRow.getDate(notSeenDuration: thread?.participants?.first?.notSeenDuration){
                            Text(lastSeen)
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        HStack{
                            Spacer()
                            ActionButton(iconSfSymbolName: "bell", iconColor: .blue , taped:{
                                viewModel.muteUnMute()
                            })
                            
                            ActionButton(iconSfSymbolName: "magnifyingglass", iconColor: .blue , taped:{
                                viewModel.searchInsideThreadMessages("")
                            })
                            
                            if let type = thread?.type, ThreadTypes(rawValue: type) == .NORMAL{
                                ActionButton(iconSfSymbolName: "hand.raised.slash", iconColor: .blue , taped:{
                                })
                            }
                            Spacer()
                        }
                        .padding(SwiftUI.EdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8))
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(16)
                    }
                    .noSeparators()
                    if let thread = viewModel.model.thread{
                        Section{
                            TabViewsContainer(thread:thread,selectedTabIndex: 0)
                                .ignoresSafeArea(.all,edges: [.bottom])
                                .frame(minHeight:reader.size.height + reader.safeAreaInsets.bottom)
                                .noSeparators()
                                .listRowInsets(.init())
                        }
                    }
                }
                .ignoresSafeArea(.all,edges: [.bottom])
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                self.image = image
                self.assetResource = assestResources
            }
        }
        .navigationViewStyle(.stack)
        .onAppear{
            threadTitle = viewModel.model.thread?.title ?? ""
            threadDescription = viewModel.model.thread?.description ?? ""
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing) {
                VStack (alignment:.center){
                    Button {
                        if isInEditMode{
                            //submited
                            viewModel.updateThreadInfo(threadTitle, threadDescription, image: image, assetResources: assetResource)
                        }
                        isInEditMode.toggle()
                    } label: {
                        Text(isInEditMode ? "Done" : "Edit")
                    }
                }
            }
        }
        .customAnimation(.default)
    }
    
}

struct ThreadDetailView_Previews: PreviewProvider {

    static var vm:ThreadViewModel{
        
        let thread = ThreadRow_Previews.thread
        let vm = ThreadViewModel(thread: thread)
        thread.title = "Test Thread title"
        thread.description = "Test Thread Description with slightly long text"
        return vm
    }
    
    static var previews: some View {
        ThreadDetailView(viewModel: vm)
            .preferredColorScheme(.light)
            .environmentObject(AppState.shared)
            .previewDevice("iPhone 13 Pro Max")
            .onAppear(){
                vm.setupPreview()
            }
    }
}
