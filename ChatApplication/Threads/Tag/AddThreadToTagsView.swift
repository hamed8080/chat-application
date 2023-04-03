//
//  AddThreadToTagsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import SwiftUI

struct AddThreadToTagsView: View {
    @StateObject var viewModel: TagsViewModel
    @State var showAddNewFolderDialog = false
    var onCompleted: (Tag) -> Void
    @State var tagName: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tags) { tag in
                    TagRow(tag: tag, viewModel: viewModel)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                            Button(role: .destructive) {
                                viewModel.deleteTag(tag)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }.background(Color.red)
                        })
                }
            }
            .listStyle(.plain)
            .padding(0)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Add To Folder")
            .customDialog(isShowing: $showAddNewFolderDialog) {
                PrimaryCustomDialog(title: "Add Folder",
                                    message: "Enter folder name to add threads to this folder you can manage folders from settings.",
                                    systemImageName: "folder.badge.plus",
                                    textBinding: $tagName,
                                    hideDialog: $showAddNewFolderDialog,
                                    textPlaceholder: "Enter Folder Name") { _ in
                    viewModel.createTag(name: tagName)
                }
                .keyboardResponsive()
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            if let tag = viewModel.selectedTag {
                                onCompleted(tag)
                            }
                        }
                    } label: {
                        Label {
                            Text("Done")
                                .font(.iransansCaption)
                        } icon: {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            showAddNewFolderDialog.toggle()
                        }
                    } label: {
                        Label {
                            Text("Add")
                                .font(.iransansCaption)
                        } icon: {
                            Image(systemName: "folder.badge.plus")
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    ConnectionStatusToolbar()
                }
            }
            .onAppear {
                viewModel.getTagList()
            }
        }
    }
}

struct AddThreadToTags_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = TagsViewModel()
        AddThreadToTagsView(viewModel: vm, onCompleted: { _ in
        })
        .onAppear {
            vm.setupPreview()
        }
        .environmentObject(appState)
    }
}
