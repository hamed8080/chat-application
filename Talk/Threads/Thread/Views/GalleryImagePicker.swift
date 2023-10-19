//
//  GalleryImagePicker.swift
//  Talk
//
//  Created by hamed on 10/18/23.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct GalleryImagePicker: View {
    let viewModel: ActionSheetViewModel
    @Environment(\.horizontalSizeClass) var size
    @State var selectedImageItemsCount = 0

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 96, maximum: 128), spacing: 0), count: size == .compact ? 4 : 7), spacing: 8) {
                AttachmentMessageList()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .environmentObject(viewModel)
        .onAppear {
            viewModel.oneTimeSetup()
        }
        .onDisappear {
            viewModel.refresh()
        }
        .safeAreaInset(edge: .bottom) {
            EmptyView()
                .frame(height: 72)
        }
        .overlay(alignment: .bottom) {
            HStack {
                Button {
                    withAnimation {
                        viewModel.sendSelectedPhotos()                        
                    }
                } label: {
                    Text("General.add")
                        .font(.iransansBody)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 48)
                .background(Color.main)
                .cornerRadius(8)
                .contentShape(Rectangle())
                .disabled(selectedImageItemsCount == 0)
                .opacity(selectedImageItemsCount == 0 ? 0.3 : 1.0)
            }
            .padding()
            .background(.ultraThinMaterial)
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
    @EnvironmentObject var viewModel: ActionSheetViewModel

    var body: some View {
        ForEach(viewModel.allImageItems) { item in
            AttachmentImageView(viewModel: viewModel, item: item)
        }
    }
}

struct AttachmentImageView: View {
    var viewModel: ActionSheetViewModel
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
            .cornerRadius(4)
            .overlay {
                selectRadio
            }
            .onAppear {
                if viewModel.allImageItems.last?.id == item.id {
                    viewModel.loadMore()
                }
            }
            .onTapGesture {
                Task {
                    await viewModel.toggleSelectedImage(item)
                    withAnimation(!isSelected ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.2) : .linear) {
                        isSelected = viewModel.selectedImageItems.contains(where: { $0.phAsset === item.phAsset })
                    }
                }
            }
    }

    @ViewBuilder var selectRadio: some View {
        ZStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .scaleEffect(x: isSelected ? 1 : 0.001, y: isSelected ? 1 : 0.001, anchor: .center)
                .foregroundColor(Color.blue)

            Image(systemName: "circle")
                .font(.title)
                .foregroundColor(Color.blue)
        }
        .frame(width: isSelected ? 22 : 0.001, height: isSelected ? 22 : 0.001, alignment: .center)
        .padding(isSelected ? 24 : 0.001)
        .scaleEffect(x: isSelected ? 1.0 : 0.001, y: isSelected ? 1.0 : 0.001, anchor: .center)
        .disabled(true)
        .allowsHitTesting(false)
    }
}


struct GalleryImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        GalleryImagePicker(viewModel: .init())
    }
}
