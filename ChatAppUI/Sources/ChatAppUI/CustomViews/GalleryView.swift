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
    let viewModel: GalleryViewModel

    var body: some View {
        ZStack {
            GalleryProgressView()
                .environmentObject(viewModel)
            GalleryImageViewData()
                .environmentObject(viewModel)
            GalleryTextView()
                .environmentObject(viewModel)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .fullScreenBackgroundView()
        .ignoresSafeArea(.all)
        .onAppear {
            viewModel.fetchImage()
        }
    }
}

struct GalleryProgressView: View {
    @EnvironmentObject var viewModel: GalleryViewModel

    var body: some View {
        if viewModel.state == .DOWNLOADING {
            CircularProgressView(percent: $viewModel.percent)
                .padding()
                .frame(maxWidth: 128)
        }
    }
}

struct GalleryImageViewData: View {
    @EnvironmentObject var viewModel: GalleryViewModel

    var body: some View {
        if let data = viewModel.currentData, let uiimage = UIImage(data: data) {
            GalleryImageView(uiimage: uiimage, viewModel: viewModel)
        }
    }
}

struct GalleryImageView: View {
    let uiimage: UIImage
    let viewModel: GalleryViewModel
    @Environment(\.dismiss) var dismiss
    @GestureState private var scaleBy: CGFloat = 1.0
    @State private var endScale: CGFloat = 1.0
    @State private var isDragging = false

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { _ in
                isDragging = true
            }
            .onEnded { value in
                isDragging = false
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
            .updating($scaleBy) { value, state, transaction in
                state = value
                transaction.animation = .interactiveSpring()
            }
            .onEnded{ value in
                if !isDragging {
                    endScale = value
                }
            }
    }

    var body: some View {
        Image(uiImage: uiimage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scaleBy, anchor: .center)
            .scaleEffect(endScale, anchor: .center)
            .gesture(zoomGesture)
            .gesture(dragGesture)
            .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.9), value: scaleBy)
    }
}

struct GalleryTextView: View {
    @EnvironmentObject var viewModel: GalleryViewModel

    var body: some View {
        if let message = viewModel.currentImageMessage?.message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
            VStack(alignment: .leading, spacing: 0){
                Spacer()
                HStack {
                    LongTextView(message)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                }
                .background(.ultraThickMaterial)
            }
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView(viewModel: GalleryViewModel(message: Message(message: "TEST", conversation: .init(id: 1))))
    }
}
