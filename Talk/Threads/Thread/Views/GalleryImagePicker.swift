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
import PhotosUI

struct GalleryImagePicker: View {
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: ImagePickerViewModel
    @Environment(\.horizontalSizeClass) var size
    @State var showSelecMoreDialog = false

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 96, maximum: 128), spacing: 0), count: size == .compact ? 4 : 7), spacing: 8) {
                AttachmentMessageList()
                    .fullScreenCover(isPresented: $showSelecMoreDialog) {
                        LimitedLibraryPicker() {
                            showSelecMoreDialog = false
                        }
                        .presentationBackground {
                            Color.clear
                        }
                    }
            }
            .padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
        }
        .onAppear {
            viewModel.oneTimeSetup()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if viewModel.state == .limited {
                HStack {
                    Button {
                        showSelecMoreDialog = true
                    } label: {
                        Text("General.add")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.App.blue)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 48)
                .background(.ultraThinMaterial)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: "General.add", enableButton: .constant(viewModel.selectedImageItems.count > 0), isLoading: .constant(false)) {
                threadVM.attachmentsViewModel.addSelectedPhotos()
                threadVM.sheetType = nil
                threadVM.animateObjectWillChange()
            }
        }
        .onReceive(viewModel.objectWillChange) { _ in
            if viewModel.state == .denied {
                threadVM.sheetType = nil
                threadVM.animateObjectWillChange()
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(PhotoPermissionDeniedDialog())
            }
        }
        .task {
            viewModel.loadImages()
        }
    }
}

class MYController: UIViewController {
    var onDismiss: (() -> Void)?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self) { selectedItems in
            self.onDismiss?()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
    }
}

struct LimitedLibraryPicker: UIViewControllerRepresentable {
    let onDismiss: () -> Void
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = MYController()
        controller.modalPresentationStyle = .overCurrentContext
        controller.onDismiss = onDismiss
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct PhotoPermissionDeniedDialog: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("General.galleyAccessPermissionDenied")
                .foregroundStyle(Color.App.text)
                .font(.iransansBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Button {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.placeholder)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }

                Button {
                    if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
                    }
                } label: {
                    Text("General.moveToSettings")
                        .foregroundStyle(Color.App.orange)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
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

        Text("sss")
            .fullScreenCover(isPresented: .constant(true)) {
                LimitedLibraryPicker() {
                }
                .presentationBackground(Color.gray.opacity(0.3))
            }
//        GalleryImagePicker()
    }
}
