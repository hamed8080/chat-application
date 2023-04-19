//
//  AttachmentDialog.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import AdditiveUI
import ChatAppUI
import ChatAppViewModels
import SwiftUI

struct AttachmentDialog: View {
    @EnvironmentObject var threadViewModel: ThreadViewModel
    @StateObject var viewModel: ActionSheetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PhotoGridView()
                .padding()
                .environmentObject(viewModel)
            Spacer()
            let count = viewModel.selectedImageItems.count
            let text = count > 0 ? "\(count) selected" : "Nothing Has been selected."
            Text(verbatim: text)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(uiColor: .systemGray))
                .font(.iransansCaption)
                .frame(minWidth: 0, maxWidth: .infinity)
            if viewModel.selectedImageItems.count > 0 {
                SendTextViewWithButtons {
                    viewModel.sendSelectedPhotos()
                    threadViewModel.sheetType = nil
                } onCancel: {
                    viewModel.refresh()
                    threadViewModel.sheetType = nil
                }
                .environmentObject(viewModel.threadViewModel)
            } else {
                buttons
            }
        }
        .animation(.easeInOut, value: viewModel.selectedImageItems.count)
    }

    @ViewBuilder var buttons: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button {
                threadViewModel.sheetType = .galleryPicker
            } label: {
                Label("Photo or Video", systemImage: "photo")
            }

            Button {
                threadViewModel.sheetType = .filePicker
            } label: {
                Label("File", systemImage: "doc")
            }

            Button {
                threadViewModel.sheetType = .locationPicker
            } label: {
                Label("Location", systemImage: "location.viewfinder")
            }

            Button {
                threadViewModel.sheetType = .contactPicker
            } label: {
                Label("Contact", systemImage: "person.2.crop.square.stack")
            }
        }
        .font(.iransansBody)
        .padding()
    }
}

struct PhotoGridView: View {
    @EnvironmentObject var viewModel: ActionSheetViewModel

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: .init(.adaptive(minimum: 64), spacing: 4), count: 6), spacing: 4) {
                ForEach(viewModel.allImageItems) { item in
                    let cgImage = item.imageData.imageScale(width: 256)?.image
                    Image(uiImage: UIImage(cgImage: (cgImage ?? UIImage().cgImage)!))
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 72)
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
                            if viewModel.allImageItems.last?.id == item.id {
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
        .animation(.easeInOut, value: viewModel.allImageItems.count)
        .animation(.easeInOut, value: viewModel.selectedImageItems.count)
        .onAppear {
            viewModel.loadImages()
        }
    }
}

struct AttachmentDialog_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        AttachmentDialog(viewModel: ActionSheetViewModel(threadViewModel: vm))
            .onAppear {
                vm.setup(thread: MockData.thread)
            }
    }
}
