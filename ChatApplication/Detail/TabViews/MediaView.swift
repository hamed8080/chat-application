//
//  MediaView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MediaView: View {
    var thread: Conversation
    @StateObject var viewModel: AttachmentsViewModel = .init()

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        List {
            LazyVGrid(columns: columns, alignment: .center, spacing: 4) {
                ForEach(viewModel.model.messages) { picture in
                    MediaPicture(picture: picture)
                        .onAppear {
                            if viewModel.model.messages.last == picture {
                                viewModel.loadMore()
                            }
                        }
                }
            }
            .noSeparators()
            .listRowBackground(Color.clear)
        }
        .padding(8)
        .onAppear {
            viewModel.thread = thread
            viewModel.getPictures()
        }
    }
}

struct MediaPicture: View {
    var picture: Message

    var body: some View {
        ImageLaoderView(url: picture.fileMetaData?.file?.link)
            .id("\(picture.fileMetaData?.file?.link ?? "")\(picture.id ?? 0)")
            .scaledToFit()
            .frame(height: 128)
            .padding(16)
    }
}

struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        MediaView(thread: MockData.thread)
    }
}
