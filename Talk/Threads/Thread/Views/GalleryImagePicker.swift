//
//  GalleryImagePicker.swift
//  Talk
//
//  Created by hamed on 10/18/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import TalkUI

struct GalleryImagePicker: View {
    let viewModel: AttachmentsViewModel
    @Environment(\.horizontalSizeClass) var size
    @State var selectedImageItemsCount = 0

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 96, maximum: 128), spacing: 0), count: size == .compact ? 4 : 7), spacing: 8) {
                AttachmentMessageList()
            }
            .padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
        }
        .environmentObject(viewModel)
        .onAppear {
            viewModel.oneTimeSetup()
        }
        .onDisappear {
            viewModel.refresh()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: "General.add", enableButton: .constant(selectedImageItemsCount > 0), isLoading: .constant(false)) {
                viewModel.addSelectedPhotos()
            }
        }
        .task {
            await viewModel.loadImages()
        }
        .onReceive(viewModel.objectWillChange) { newValue in
            selectedImageItemsCount = viewModel.selectedImageItems.count
        }
    }
}

struct AttachmentMessageList: View {
    @EnvironmentObject var viewModel: AttachmentsViewModel

    var body: some View {
        ForEach(viewModel.allImageItems) { item in
            AttachmentImageView(viewModel: viewModel, item: item)
        }
    }
}

struct AttachmentImageView: View {
    var viewModel: AttachmentsViewModel
    var item: ImageItem
    var image: UIImage { UIImage(data: item.imageData)! }
    @State private var isSelected: Bool = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 96, height: 96)
            .clipped()
            .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
            .clipShape(RoundedRectangle(cornerRadius:(4)))
            .overlay {
                RadioButton(visible: .constant(true), isSelected: $isSelected) { _ in
                    Task {
                        await viewModel.toggleSelectedImage(item)
                        withAnimation(!isSelected ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.2) : .linear) {
                            isSelected = viewModel.selectedImageItems.contains(where: { $0.phAsset === item.phAsset })
                        }
                    }
                }
            }
            .onAppear {
                if viewModel.allImageItems.last?.id == item.id {
                    viewModel.loadMore()
                }
            }
    }
}


struct GalleryImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        GalleryImagePicker(viewModel: .init())
    }
}
