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
    @EnvironmentObject var threadVM: ThreadViewModel
    var attachmentVM: AttachmentsViewModel { threadVM.attachmentsViewModel }
    @Environment(\.horizontalSizeClass) var size
    @State private var selectedCount = 0

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 96, maximum: 128), spacing: 0), count: size == .compact ? 4 : 7), spacing: 8) {
                AttachmentMessageList()
            }
            .padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
        }
        .environmentObject(attachmentVM.imagePickerViewModel)
        .onAppear {
            attachmentVM.imagePickerViewModel.oneTimeSetup()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: "General.add", enableButton: .constant(selectedCount > 0), isLoading: .constant(false)) {
                attachmentVM.addSelectedPhotos()
                threadVM.sheetType = nil
                threadVM.animateObjectWillChange()
            }
        }
        .onReceive(attachmentVM.imagePickerViewModel.objectWillChange) { _ in
            if attachmentVM.imagePickerViewModel.selectedImageItems.count != selectedCount {
                selectedCount = attachmentVM.imagePickerViewModel.selectedImageItems.count
            }
        }
        .task {
            attachmentVM.imagePickerViewModel.loadImages()
        }
    }
}

struct AttachmentMessageList: View {
    @EnvironmentObject var viewModel: ImagePickerViewModel

    var body: some View {
        ForEach(viewModel.allImageItems) { item in
            AttachmentImageView(viewModel: viewModel)
                .environmentObject(item)
        }
    }
}

struct AttachmentImageView: View {
    let viewModel: ImagePickerViewModel
    @EnvironmentObject var item: ImageItem
    @State private var isSelected: Bool = false

    var body: some View {
        ImagePickerImageHolder()
            .overlay {
                if item.isIniCloud {
                    DownloadFromiCloudProgress(viewModel: viewModel)
                } else {
                    RadioButton(visible: .constant(true), isSelected: $isSelected) { _ in
                        Task {
                            await viewModel.toggleSelectedImage(item)
                            withAnimation(!isSelected ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.2) : .linear) {
                                isSelected = viewModel.selectedImageItems.contains(where: { $0.phAsset === item.phAsset })
                            }
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

struct ImagePickerImageHolder: View {
    @EnvironmentObject var item: ImageItem

    var body: some View {
        Image(uiImage: UIImage(data: item.imageData) ?? .init())
            .resizable()
            .scaledToFill()
            .frame(width: 96, height: 96)
            .clipped()
            .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
            .clipShape(RoundedRectangle(cornerRadius:(4)))
    }
}

struct DownloadFromiCloudProgress: View {
    let viewModel: ImagePickerViewModel
    @EnvironmentObject var item: ImageItem

    var body: some View {
        ZStack {
            Image(systemName: "icloud.and.arrow.down")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Circle()
                .trim(from: 0.0, to: item.icouldDownloadProgress)
                .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.App.primary)
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 28, height: 28)
                .environment(\.layoutDirection, .leftToRight)
        }
        .animation(.easeInOut, value: item.icouldDownloadProgress)
        .onTapGesture {
            viewModel.downloadFromiCloud(item)
        }
    }
}

struct GalleryImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        GalleryImagePicker()
    }
}
