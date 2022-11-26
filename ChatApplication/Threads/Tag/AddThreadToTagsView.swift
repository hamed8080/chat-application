//
//  AddThreadToTagsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct AddThreadToTagsView:View {
    
    @StateObject
    var viewModel:TagsViewModel
    
    @EnvironmentObject var appState:AppState
    
    @State var title    :String  = "Add To Folder"
    
    @State
    var showAddNewFolderDialog = false
    
    var onCompleted:(Tag)->()
    
    @State
    var tagName:String = ""
    
    var body: some View{
        GeometryReader{ reader in
            PageWithNavigationBarView(title:$title, subtitle:$appState.connectionStatusString,trailingItems: getTrailingItems(), leadingItems: getLeadingItems()){
                VStack(alignment:.leading,spacing: 0){
                    List {
                        ForEach(viewModel.tags , id:\.id) { tag in
                            TagRow(tag: tag, viewModel: viewModel)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                    Button(role:.destructive) {
                                        viewModel.deleteTag(tag)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }.background(Color.red)
                                })
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                .padding(0)
                Spacer()
            }
        }
        .customDialog(isShowing: $showAddNewFolderDialog) {
            PrimaryCustomDialog(title: "Add Folder",
                                message: "Enter folder name to add threads to this folder you can manage folders from settings.",
                                systemImageName: "folder.badge.plus",
                                textBinding: $tagName,
                                hideDialog: $showAddNewFolderDialog,
                                textPlaceholder: "Enter Folder Name")
            { textFieldValue in
                viewModel.createTag(name: tagName)
            }
            .keyboardResponsive()
            .padding()
        }
        .onAppear {
            viewModel.getOfflineTags()
        }
    }
    
    func getTrailingItems()->[NavBarItem]{
        return [NavBarButton(title: "Add", isBold: true) {
            withAnimation {
                if let tag = viewModel.selectedTag {
                    onCompleted(tag)
                }
            }
        }.getNavBarItem()]
    }
    
    func getLeadingItems()->[NavBarItem]{
        return [NavBarButton(systemImageName:"folder.badge.plus", isBold: true) {
            withAnimation {
                showAddNewFolderDialog.toggle()
            }
        }.getNavBarItem()]
    }
}

struct AddThreadToTags_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = TagsViewModel()
        AddThreadToTagsView(viewModel: vm, onCompleted: { model in
        })
            .onAppear(){
                vm.setupPreview()
            }
            .environmentObject(appState)
    }
}
