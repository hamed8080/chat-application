//
//  AttachmentDialog.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import SwiftUI

struct AttachmentDialog: View {
    @StateObject var viewModel: ActionSheetViewModel
    @Binding var showAttachmentDialog: Bool
    @State var showDocumentPicker: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            let count = viewModel.selectedImageItems.count
            let text = count > 0 ? "\(count) selected" : "Nothing Has been selected."
            Text(verbatim: text)
                .multilineTextAlignment(.center)
                .font(.title2.bold())
                .foregroundColor(.tableItem)
                .frame(minWidth: 0, maxWidth: .infinity)
            Spacer()
            PhotoGridView()
                .environmentObject(viewModel)
            if viewModel.selectedImageItems.count > 0 {
                Button {
                    viewModel.sendSelectedPhotos()
                    showAttachmentDialog.toggle()
                } label: {
                    Label("Send", systemImage: "paperplane")
                }

                Button(role: .destructive) {
                    viewModel.refresh()
                } label: {
                    Label("Close", systemImage: "xmark.square")
                }
            } else {
                Button {
                    showAttachmentDialog.toggle()
                } label: {
                    Label("Photo or Video", systemImage: "photo")
                }

                Button {
                    showAttachmentDialog.toggle()
                    showDocumentPicker = true
                } label: {
                    Label("File", systemImage: "doc")
                }

                Button {
                    showAttachmentDialog.toggle()
                } label: {
                    Label("Location", systemImage: "location.viewfinder")
                }

                Button {
                    showAttachmentDialog.toggle()
                } label: {
                    Label("Contact", systemImage: "person.2.crop.square.stack")
                }
            }
        }
        .animation(.easeInOut, value: viewModel.selectedImageItems.count)
        .padding()
        .sheet(isPresented: $showDocumentPicker, onDismiss: nil) {
            DocumentPicker(fileUrl: $viewModel.selectedFileUrl, showDocumentPicker: $showDocumentPicker)
        }
    }
}

struct PhotoGridView: View {
    @EnvironmentObject var viewModel: ActionSheetViewModel

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                ForEach(viewModel.allImageItems) { item in
                    Image(uiImage: item.image)
                        .resizable()
                        .frame(width: 96, height: 96)
                        .scaledToFit()
                        .overlay {
                            VStack {
                                HStack {
                                    Spacer()
                                    let isSelected = viewModel.selectedImageItems.contains(where: { $0.phAsset === item.phAsset })
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .font(.title)
                                            .padding([.top, .trailing], 4)
                                            .foregroundColor(Color.blue)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .onAppear {
                            if viewModel.allImageItems.last?.id.uuidString == item.id.uuidString {
                                viewModel.loadMore()
                            }
                        }
                        .onTapGesture {
                            viewModel.toggleSelectedImage(item)
                        }
                }
                if viewModel.isLoading {
                    LoadingView(isAnimating: viewModel.isLoading)
                }
            }
        }
        .frame(height: 96)
        .animation(.easeInOut, value: viewModel.selectedImageItems.count)
        .onAppear {
            viewModel.loadImages()
        }
    }
}

struct AttachmentDialog_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        AttachmentDialog(viewModel: ActionSheetViewModel(threadViewModel: vm), showAttachmentDialog: .constant(true))
            .onAppear {
                vm.setup(thread: MockData.thread)
            }
    }
}
