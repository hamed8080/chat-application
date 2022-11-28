//
//  AttachmentDialog.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import SwiftUI

struct AttachmentDialog: View {
    @Binding
    var showAttachmentDialog: Bool

    @StateObject
    var viewModel: ActionSheetViewModel

    var body: some View {
        VStack {
            Spacer()
            CustomActionSheetView(viewModel: viewModel, showAttachmentDialog: $showAttachmentDialog)
                .offset(y: showAttachmentDialog ? 0 : UIScreen.main.bounds.height)
                .animation(.spring(), value: showAttachmentDialog)
                .animation(.spring(), value: viewModel.selectedImageItems.count)
        }
        .frame(width: showAttachmentDialog ? .infinity : 0, height: showAttachmentDialog ? .infinity : 0) // frame must be set to zero because textview will be coverd with auto correction on keyboard
        .background((showAttachmentDialog ? Color.gray.opacity(0.3).ignoresSafeArea() : Color.clear.ignoresSafeArea())
            .onTapGesture {
                viewModel.clearSelectedPhotos()
                showAttachmentDialog.toggle()
            }
        )
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct CustomActionSheetView: View {
    @StateObject
    var viewModel: ActionSheetViewModel

    @Binding
    var showAttachmentDialog: Bool

    @State
    var showDocumentPicker: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            if viewModel.allImageItems.count > 0 {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 8) {
                        ForEach(viewModel.allImageItems, id: \.self) { item in
                            ZStack {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .frame(width: 96, height: 96)
                                    .scaledToFit()
                                    .cornerRadius(12)

                                let isSelected = viewModel.selectedImageItems.contains(where: { $0.phAsset === item.phAsset })
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .font(.title)
                                            .padding([.top, .trailing], 4)
                                            .foregroundColor(Color.blue)
                                    }
                                    Spacer()
                                }
                            }
                            .onAppear(perform: {
                                if viewModel.allImageItems.last == item {
                                    viewModel.loadMore()
                                }
                            })
                            .onTapGesture {
                                viewModel.toggleSelectedImage(item)
                            }
                        }
                        if viewModel.isLoading {
                            LoadingView(isAnimating: viewModel.isLoading)
                        }
                    }
                    .frame(height: 96)
                    .padding([.leading], 16)
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.selectedImageItems.count > 0 {
                    AttachmentButton(title: "Send", imageName: "paperplane") {
                        viewModel.sendSelectedPhotos()
                        showAttachmentDialog.toggle()
                    }

                    AttachmentButton(title: "Close", imageName: "xmark.square", hideDivider: true) {
                        viewModel.clearSelectedPhotos()
                    }
                } else {
                    AttachmentButton(title: "Photo or Video", imageName: "photo.on.rectangle.angled") {}

                    AttachmentButton(title: "File", imageName: "doc") {
                        showDocumentPicker = true
                        showAttachmentDialog = false
                    }

                    AttachmentButton(title: "Location", imageName: "location.viewfinder") {}

                    AttachmentButton(title: "Contact", imageName: "person.2.crop.square.stack", hideDivider: true) {}
                }
            }
            .padding([.leading], 24)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showDocumentPicker, onDismiss: nil) {
            DocumentPicker(fileUrl: $viewModel.selectedFileUrl, showDocumentPicker: $showDocumentPicker)
        }.onAppear(perform: {
            viewModel.loadImages()
        })
        .padding(.top, 24)
        .padding(.bottom, ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 0) + 10)
        .background(.thinMaterial)
        .cornerRadius(16, corners: [.topLeft, .topRight])
    }
}

struct AttachmentButton: View {
    let title: String
    let imageName: String
    var hideDivider = false
    var action: () -> ()

    var body: some View {
        Button {
            action()
        } label: {
            Label(title, systemImage: imageName)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 48, alignment: .leading)
        }
        .font(.title3.weight(.medium))
        .contentShape(Rectangle(), eoFill: true)
        if !hideDivider {
            Divider()
        }
    }
}

struct AttachmentDialog_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentDialog(showAttachmentDialog: .constant(true),
                         viewModel: ActionSheetViewModel(threadViewModel: ThreadViewModel(thread: MockData.thread)))
    }
}
