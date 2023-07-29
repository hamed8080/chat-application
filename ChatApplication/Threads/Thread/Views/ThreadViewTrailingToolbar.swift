//
//  ThreadViewTrailingToolbar.swift
//  ChatApplication
//
//  Created by hamed on 7/9/23.
//

import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ThreadViewTrailingToolbar: View {
    private var thread: Conversation { viewModel.thread }
    let viewModel: ThreadViewModel

    var body: some View {
        NavigationLink {
            DetailView()
                .environmentObject(viewModel.detailVM)
                .environmentObject(viewModel)
        } label: {
            ImageLaoderView(url: thread.computedImageURL, userName: thread.title)
                .id("\(thread.id ?? 0)\(thread.computedImageURL ?? "")")
                .font(.iransansBody)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(16)
                .cornerRadius(18)
        }

        Menu {
            Button {
                viewModel.sheetType = .datePicker
                viewModel.animatableObjectWillChange()
            } label: {
                Label {
                    Text("Export")
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .scaledToFit()
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}

struct ThreadViewTrailingToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewTrailingToolbar(viewModel: ThreadViewModel(thread: Conversation()))
    }
}
