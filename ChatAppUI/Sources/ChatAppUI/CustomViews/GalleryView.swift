//
//  GalleryView.swift
//  ChatApplication
//
//  Created by hamed on 3/14/23.
//

import ChatAppViewModels
import ChatModels
import SwiftUI
import OSLog

public struct GalleryView: View {
    @StateObject var viewModel: GalleryViewModel

    public init(message: Message) {
        self._viewModel = StateObject(wrappedValue: .init(message: message))
    }

    public var body: some View {
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
            CircularProgressView(percent: $viewModel.percent, config: .normal)
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

public struct GalleryImageView: View {
    let uiimage: UIImage
    let viewModel: GalleryViewModel?
    @Environment(\.dismiss) var dismiss
    @GestureState private var scaleBy: CGFloat = 1.0
    @State private var endScale: CGFloat = 1.0
    @State private var isDragging = false
    @State var dragOffset: CGSize = .zero
    @State private var previousDragOffset: CGSize = .zero
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "GalleryImageView")

    public init(uiimage: UIImage, viewModel: GalleryViewModel? = nil) {
        self.uiimage = uiimage
        self.viewModel = viewModel
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                logger.info("OnChanged dragGesture before: previousDragoffset: \(previousDragOffset.debugDescription) endScale: \(endScale) isDragging: \(isDragging) valueTranslation: \(value.translation.debugDescription)")
                isDragging = true
                dragOffset.width = value.translation.width + previousDragOffset.width
                dragOffset.height = value.translation.height + previousDragOffset.height
                logger.info("OnChanged dragGesture after: previousDragoffset: \(previousDragOffset.debugDescription) endScale: \(endScale) isDragging: \(isDragging) valueTranslation: \(value.translation.debugDescription)")
            }
            .onEnded { value in
                logger.info("OnEnded dragGesture before: endScale: \(endScale) isDragging: \(isDragging) valueTRanslation: \(value.translation.debugDescription)")
                isDragging = false
                previousDragOffset = dragOffset
                if value.translation.width > 100 {
                    // swipe right
                    viewModel?.swipeTo(.previous)
                }

                if value.translation.width < 100 {
                    // swipe left
                    viewModel?.swipeTo(.next)
                }

                if value.translation.height > 100, endScale <= 1.0, abs(value.translation.width) < 42 {
                    // swipe down
                    dismiss()
                }
                logger.info("OnEnded dragGesture after: endScale: \(endScale) isDragging: \(isDragging) valueTRanslation: \(value.translation.debugDescription)")
            }
    }

    var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($scaleBy) { value, state, transaction in
                logger.info("OnUpdating zoomGesture before: endScale: \(endScale) isDragging: \(isDragging)")
                state = value
                transaction.animation = .interactiveSpring()
                logger.info("OnUpdating zoomGesture after: endScale: \(endScale) isDragging: \(isDragging)")
            }
            .onEnded{ value in
                if !isDragging {
                    logger.info("OnEnded zoomGesture before: endScale: \(endScale) isDragging: \(isDragging)")
                    endScale = value
                    logger.info("OnEnded zoomGesture after: endScale: \(endScale) isDragging: \(isDragging)")
                }
            }
    }

    public var body: some View {
        ZStack {
            Image(uiImage: uiimage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scaleBy, anchor: .center)
                .scaleEffect(endScale, anchor: .center)
                .offset(dragOffset)
                .gesture(dragGesture)
                .gesture(zoomGesture)
                .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.9), value: scaleBy)
            DismissGalleryButton()
        }
    }
}

struct DismissGalleryButton: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.orange, .ultraThinMaterial)
                        .background(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .cornerRadius(22)
                        .padding([.top])
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
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
                .background(.ultraThinMaterial)
            }
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView(message: Message(message: "TEST", conversation: .init(id: 1)))
    }
}
