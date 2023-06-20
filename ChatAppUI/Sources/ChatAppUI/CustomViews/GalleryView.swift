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
    @State var scaleBy: CGFloat = 1.0

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

    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged{ newValue in
                scaleBy = newValue
            }
    }

    var body: some View {
        ZStack {
            if viewModel.state == .DOWNLOADING {
                CircularProgressView(percent: $viewModel.percent)
                    .padding()
                    .frame(maxWidth: 128)
            }
            if let data = viewModel.currentData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scaleBy, anchor: .center)
                    .gesture(zoomGesture)
                    .animation(.easeInOut, value: scaleBy)
            }

            if let message = viewModel.currentImageMessage?.message {
                VStack (alignment: .leading){
                    Spacer()
                    Text(message)
                }
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
