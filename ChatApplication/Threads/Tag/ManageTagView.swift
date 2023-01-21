//
//  ManageTagView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import SwiftUI

struct ManageTagView: View {
    var tag: Tag
    @StateObject var viewModel: TagsViewModel
    @EnvironmentObject var appState: AppState
    @State var showAddNewFolderDialog = false
    var onCompleted: (Tag) -> Void
    @State var tagName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Spacer()
                        Image(systemName: "folder.fill.badge.gearshape")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .foregroundColor(Color.blue.opacity(0.7))
                        Spacer()
                    }

                    HStack {
                        Spacer()
                        Text("Manage folders")
                            .foregroundColor(.gray)
                        Spacer()
                    }

                    PrimaryTextField(title: "Folder Name",
                                     textBinding: $tagName,
                                     isEditing: false,
                                     keyboardType: .default,
                                     corenrRadius: 12,
                                     backgroundColor: Color.white,
                                     onCommit: {})
                        .onAppear(perform: {
                            tagName = tag.name
                        })

                    if let tagParticipants = tag.tagParticipants {
                        List {
                            ForEach(tagParticipants) { tagParticipant in
                                TagParticipantRow(tag: tag, tagParticipant: tagParticipant, viewModel: viewModel)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                        Button(role: .destructive) {
                                            viewModel.deleteTagParticipant(tag.id, tagParticipant)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }.background(Color.red)
                                    })
                            }
                        }
                        .listStyle(.plain)
                        .cornerRadius(12)
                        .clipped()
                    }
                }
                .padding(16)
            }
            .navigationTitle("Manage Folder")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            let tag = Tag(id: tag.id, name: tagName, active: tag.active, tagParticipants: tag.tagParticipants)
                            viewModel.editTag(tag: tag)
                        }
                    } label: {
                        Label {
                            Text("Done")
                        } icon: {
                            Image(systemName: "square.and.arrow.down")
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

struct ManageTagView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = TagsViewModel()
        ManageTagView(tag: MockData.tag, viewModel: vm, onCompleted: { _ in
        })
        .onAppear {
            vm.setupPreview()
        }
        .environmentObject(appState)
    }
}
