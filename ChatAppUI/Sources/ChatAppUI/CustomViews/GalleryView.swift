//
//  GalleryView.swift
//  ChatApplication
//
//  Created by hamed on 3/14/23.
//

import ChatAppViewModels
import ChatModels
import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var viewModel: GalleryViewModel
    @Environment(\.dismiss) var dismiss

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onEnded { value in

                if value.translation.width > 100 {
                    // swipe right
                    viewModel.swipeTo(.previous)
                }

                if value.translation.width < 100 {
                    // swipe left
                    viewModel.swipeTo(.next)
                }

                if value.translation.height > 100 {
                    // swipe down
                    dismiss()
                }
            }

    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let data = viewModel.currentData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .fullScreenBackgroundView()
        .gesture(dragGesture)
        .ignoresSafeArea(.all)
        .animation(.easeInOut, value: viewModel.currentData)
        .animation(.easeInOut, value: viewModel.isLoading)
        .onAppear {
            viewModel.fetchImage()
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
            .environmentObject(GalleryViewModel(message: Message(message: "TEST", conversation: .init(id: 1))))
    }
}
