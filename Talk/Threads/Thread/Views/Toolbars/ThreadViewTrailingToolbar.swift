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
    @EnvironmentObject var navVM: NavigationModel
    @State var imageViewModel: ImageLoaderViewModel?

    var body: some View {
        Button {
            navVM.append(threadViewModel: viewModel)
        } label: {
            ZStack {
                if let imageViewModel {
                    ImageLoaderView(imageLoader: imageViewModel, url: thread.computedImageURL, userName: thread.title)
                } else {
                    Text(verbatim: String(thread.computedTitle.trimmingCharacters(in: .whitespacesAndNewlines).first ?? " "))
                }
            }
            .id("\(thread.id ?? 0)\(thread.computedImageURL ?? "")")
            .font(.iransansBody)
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(Color.App.blue.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius:(16)))
        }
        .onAppear {
            updateImageLoaderViewModel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .thread)) { notification in
            if let threadEvent = notification.object as? ThreadEventTypes, case .updatedInfo(let resposne) = threadEvent, resposne.result?.id == thread.id {
                updateImageLoaderViewModel()
            }
        }
    }

    func updateImageLoaderViewModel() {
        if let image = thread.computedImageURL, let avatarVM = viewModel.threadsViewModel?.avatars(for: image) {
            imageViewModel = avatarVM
        }
    }
}

struct ThreadViewTrailingToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewTrailingToolbar(viewModel: ThreadViewModel(thread: Conversation()))
            .environmentObject(NavigationModel())
    }
}
