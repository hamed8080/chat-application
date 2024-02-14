//
//  ThreadViewTrailingToolbar.swift
//  Talk
//
//  Created by hamed on 7/9/23.
//

import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import Chat

struct ThreadViewTrailingToolbar: View {
    private var thread: Conversation { viewModel.thread }
    let viewModel: ThreadViewModel
    @State var imageLoader: ImageLoaderViewModel?

    var body: some View {
        Button {
            AppState.shared.objectsContainer.navVM.appendThreadDetail(threadViewModel: viewModel)
        } label: {
            ZStack {
                if thread.type == .selfThread {
                    SelfThreadImageView(imageSize: 36, iconSize: 16)
                } else if let imageLoader = imageLoader {
                    ImageLoaderView(imageLoader: imageLoader, textFont: .iransansCaption3)
                } else {
                    Text(verbatim: String.splitedCharacter(thread.computedTitle))
                }
            }
            .id("\(thread.id ?? 0)\(thread.computedImageURL ?? "")")
            .font(.iransansCaption3)
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(String.getMaterialColorByCharCode(str: thread.computedTitle))
            .clipShape(RoundedRectangle(cornerRadius:(15)))
            .padding(.trailing, 8)
        }
        .onReceive(NotificationCenter.thread.publisher(for: .thread)) { notification in
            if let threadEvent = notification.object as? ThreadEventTypes, case .updatedInfo(let resposne) = threadEvent, resposne.result?.id == thread.id {
                setImageLoader()
            }
        }
        .task {
            setImageLoader()
        }
    }

    private func setImageLoader() {
        if let image = thread.computedImageURL, let avatarVM = viewModel.threadsViewModel?.avatars(for: image, metaData: nil, userName: String.splitedCharacter(thread.title ?? "")) {
            imageLoader = avatarVM
        }
    }
}

struct ThreadViewTrailingToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewTrailingToolbar(viewModel: ThreadViewModel(thread: Conversation()))
            .environmentObject(NavigationModel())
    }
}
