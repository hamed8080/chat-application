//
//  TagRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct TagRow: View {
    var tag: Tag

    @StateObject var viewModel: TagsViewModel
    @State var isSelected: Bool = false
    @State var showManageTag: Bool = false

    var body: some View {
        Button(action: {
            isSelected.toggle()
            viewModel.toggleSelectedTag(tag: tag, isSelected: isSelected)
        }, label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: viewModel.selectedTag?.id == tag.id ? "checkmark.circle" : "circle")
                            .font(.title)
                            .frame(width: 22, height: 22, alignment: .center)
                            .foregroundColor(Color.blue)
                            .padding(12)

                        Image(systemName: "folder.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .scaledToFit()
                            .foregroundColor(Color.gray.opacity(0.8))
                        VStack(alignment: .leading) {
                            Text(tag.name)
                                .font(.headline)
                            Text("\(tag.tagParticipants?.count ?? 0)")
                                .lineLimit(1)
                                .font(.subheadline)
                        }
                        Spacer()

                        Button {
                            showManageTag.toggle()
                        } label: {
                            Image(systemName: "chevron.forward.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.blue.opacity(0.7))
                                .padding(8)
                        }
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding([.leading, .trailing], 8)
            .padding([.top, .bottom], 4)
        })
        .animation(.easeInOut, value: showManageTag)
        .animation(.easeInOut, value: isSelected)
        .sheet(isPresented: $showManageTag, onDismiss: nil, content: {
            ManageTagView(tag: tag, viewModel: viewModel) { _ in
            }
        })
        .contextMenu {
            Button {
                viewModel.deleteTag(tag)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct TagRow_Previews: PreviewProvider {
    static var previews: some View {
        TagRow(tag: MockData.tag, viewModel: TagsViewModel())
    }
}
