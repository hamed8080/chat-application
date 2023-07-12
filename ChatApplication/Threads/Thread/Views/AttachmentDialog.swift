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
    private var threadVM: ThreadViewModel { viewModel.threadViewModel }
    @StateObject var viewModel: ActionSheetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PhotoGridView()
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
                    threadVM.sheetType = nil
                    threadVM.animatableObjectWillChange()
                } onCancel: {
                    viewModel.refresh()
                    threadVM.sheetType = nil
                    threadVM.animatableObjectWillChange()
                }
                .environmentObject(viewModel.threadViewModel)
            } else {
                buttons
            }
        }
    }

    @ViewBuilder var buttons: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button {
                threadVM.sheetType = .galleryPicker
                threadVM.animatableObjectWillChange()
            } label: {
                Label("Photo or Video", systemImage: "photo")
            }

            Button {
                threadVM.sheetType = .filePicker
                threadVM.animatableObjectWillChange()
            } label: {
                Label("File", systemImage: "doc")
            }

            Button {
                threadVM.sheetType = .locationPicker
                threadVM.animatableObjectWillChange()
            } label: {
                Label("Location", systemImage: "location.viewfinder")
            }

            Button {
                threadVM.sheetType = .contactPicker
                threadVM.animatableObjectWillChange()
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
    @Environment(\.horizontalSizeClass) var size

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 96, maximum: 128), spacing: 0), count: size == .compact ? 4 : 7), spacing: 4) {
                ForEach(viewModel.allImageItems) { item in
                    Image(uiImage: UIImage(data: item.imageData)!)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipped()
                        .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
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
                            Task {
                                await viewModel.toggleSelectedImage(item)
                            }
                        }
                }
            }
        }
        .onDisappear {
            viewModel.refresh()
        }
        .task {
            await viewModel.loadImages()
        }
    }
}

struct AttachmentDialog_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel(thread: MockData.thread)
        AttachmentDialog(viewModel: ActionSheetViewModel(threadViewModel: vm))
    }
}
