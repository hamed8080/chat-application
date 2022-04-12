//
//  AttachmentDialog.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import SwiftUI


struct AttachmentDialog : View {
    
    @Binding
    var showAttachmentDialog: Bool
    
    @StateObject
    var viewModel: ActionSheetViewModel
    
    var body: some View{
        ZStack{
            VStack{
                Spacer()
                CustomActionSheetView(viewModel: viewModel, showAttachmentDialog: $showAttachmentDialog)
                    .offset(y: showAttachmentDialog ? 0 : UIScreen.main.bounds.height)
            }
            .background((showAttachmentDialog ? Color.gray.opacity(0.3).ignoresSafeArea() : Color.clear.ignoresSafeArea())
                            .onTapGesture {
                viewModel.clearSelectedPhotos()
                showAttachmentDialog.toggle()
            }
            )
            .edgesIgnoringSafeArea(.bottom)
        }
        .customAnimation(.default)
    }
}

struct CustomActionSheetView:View{
    
    @StateObject
    var viewModel: ActionSheetViewModel
    
    @Binding
    var showAttachmentDialog: Bool
    
    @State
    var showDocumentPicker:Bool = false
    
    var body: some View{
        
        VStack(spacing:24){
            if viewModel.allImageItems.count > 0{
                ScrollView(.horizontal){
                    HStack {
                        ForEach(viewModel.allImageItems , id:\.self){ item in
                            ZStack{
                                Image(uiImage: item.image)
                                    .resizable()
                                    .frame(width: 96, height: 96)
                                    .scaledToFit()
                                    .cornerRadius(12)
                                let isSelected = viewModel.selectedImageItems.contains(where: {$0.phAsset === item.phAsset})
                                VStack{
                                    HStack{
                                        Spacer()
                                        Image(systemName: isSelected ? "checkmark.circle" : "circle")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .font(.title)
                                            .padding([.top , .trailing], 4)
                                            .background(Color.white.blur(radius: 16))
                                            .foregroundColor(Color.blue)
                                    }
                                    Spacer()
                                }
                            }
                            .onTapGesture {
                                viewModel.toggleSelectedImage(item)
                            }
                            .frame(width: 96, height: 96)
                        }
                    }.padding([.leading], 16)
                }
            }
            
            if viewModel.selectedImageItems.count > 0 {
                Button {
                    viewModel.sendSelectedPhotos()
                    showAttachmentDialog.toggle()
                } label: {
                    Text("Send".uppercased())
                        .font(.system(size: 22).bold())
                }
                Button { viewModel.clearSelectedPhotos() } label: { Text("Cancel") }
            }else{
                Button {
                    
                } label: {
                    Text("Photo or Video")
                        .frame(height:44)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    showDocumentPicker = true
                    showAttachmentDialog = false
                } label: {
                    Text("File")
                        .frame(height:44)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    
                } label: {
                    Text("Location")
                        .frame(height:44)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    
                } label: {
                    Text("Contact")
                        .frame(height:44)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showDocumentPicker, onDismiss: nil) {
            DocumentPicker(fileUrl: $viewModel.selectedFileUrl, showDocumentPicker: $showDocumentPicker)
        }.onAppear(perform: {
            viewModel.fecthAllPhotos()
        })
            .padding(.top ,24)
            .padding(.bottom , (UIApplication.shared.windows.last?.safeAreaInsets.bottom)! + 10)
            .background(Color.white.ignoresSafeArea())
            .cornerRadius(16)
    }
}


struct AttachmentDialog_Previews: PreviewProvider {
    
    static var previews: some View {
        
        AttachmentDialog(showAttachmentDialog: .constant(true),
                         viewModel: ActionSheetViewModel(threadViewModel: ThreadViewModel(thread: MockData.thread)))
    }
}

