//
//  ThreadSheetView.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import UniformTypeIdentifiers

/// We have to use this due to in the ThreadView we used let viewModel in it will never trigger the sheet.
struct SheetEmptyBackground: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    var sheetBinding: Binding<Bool> { Binding(get: { viewModel.sheetType != nil }, set: { _ in }) }

    var body: some View {
        Color.clear
            .sheet(isPresented: sheetBinding) {
                ThreadSheetView(sheetBinding: sheetBinding)
                    .environmentObject(viewModel)
                    .environmentObject(viewModel.attachmentsViewModel)
            }
    }
}

struct ThreadSheetView: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var sheetBinding: Bool

    var body: some View {
        switch viewModel.sheetType {
        case .attachment:
            EmptyView()
        case .datePicker:
            DateSelectionView(showDialog: $sheetBinding) { startDate, endDate in
                viewModel.sheetType = nil
                viewModel.setupExportMessage(startDate: startDate, endDate: endDate)
            }
            .onDisappear {
                closeSheet()
            }
        case .exportMessagesFile:
            if let exportFileUrl = viewModel.exportMessagesViewModel.filePath {
                ActivityViewControllerWrapper(activityItems: [exportFileUrl])
                    .onDisappear {
                        viewModel.exportMessagesViewModel.deleteFile()
                        closeSheet()
                    }
            } else {
                EmptyView()
            }
        case .threadPicker:
            SelectConversationOrContactList { (conversation, contact) in
                viewModel.sendMessageViewModel.openDestinationConversationToForward(conversation, contact)
                viewModel.selectedMessagesViewModel.clearSelection() // it is essential to clean up the ui after the user tap on either a contact or a thread
            }
            .onDisappear {
                closeSheet()
            }
        case .filePicker:
            DocumentPicker { urls in
                viewModel.attachmentsViewModel.filePickerViewModel.selectedFileUrls = urls
                viewModel.attachmentsViewModel.addSelectedFile()
                viewModel.sheetType = nil
                viewModel.animateObjectWillChange()
                Task {
                    await viewModel.scrollVM.scrollToEmptySpace()
                }
            }
            .onDisappear {
                closeSheet()
            }
        case .locationPicker:
            MapPickerView()
                .environmentObject(viewModel)
                .onDisappear {
                    Task {
                        await viewModel.scrollVM.scrollToEmptySpace()
                        closeSheet()
                    }
                }
        case .galleryPicker:
            MyPHPicker() { itemProviders in

                itemProviders.forEach { provider in
                    let name = provider.suggestedName ?? "unknown"
                    if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                        _ = provider.loadDataRepresentation(for: .movie) { data, error in
                            Task {
                                if let data = data {
                                    await processVideo(data: data, name: name)
                                }
                            }
                        }
                    }

                    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        provider.loadObject(ofClass: UIImage.self) { item, error in
                            if let image = item as? UIImage {
                                Task {
                                    await processImage(image: image, name: name)
                                }
                            }
                        }
                    }
                }
                Task {
                    await viewModel.scrollVM.scrollToEmptySpace()
                }
            }
            .onDisappear {
                closeSheet()
            }
        default:
            Text("Sheet \(viewModel.sheetType.debugDescription) not implemented yet.")
        }
    }

    private func closeSheet() {
        sheetBinding = false
        viewModel.sheetType = nil
        viewModel.animateObjectWillChange()
    }

    private func processImage(image: UIImage, name: String) async {
        let data = await lessThanTwoMegabyteImage(image: image, quality: 100) ?? .init()
        let image = UIImage(data: data) ?? .init()
        let item = ImageItem(data: data,
                             width: Int(image.size.width),
                             height: Int(image.size.height),
                             originalFilename: name)
        await MainActor.run {
            viewModel.attachmentsViewModel.addSelectedPhotos(imageItem: item)
            viewModel.animateObjectWillChange() /// Send button to appear
        }
    }

    private func processVideo(data: Data, name: String) async {
        let item = ImageItem(isVideo: true,
                             data: data,
                             width: 0,
                             height: 0,
                             originalFilename: name)
        self.viewModel.attachmentsViewModel.addSelectedPhotos(imageItem: item)
        viewModel.animateObjectWillChange() /// Send button to appear
    }

    private func lessThanTwoMegabyteImage(image: UIImage, quality: CGFloat) async -> Data? {
        let data = autoreleasepool { image.jpegData(compressionQuality: quality / 100.0) }
        // It means the compression won't work anymore than this.
        if quality == 1 {
            return data
        }
        if let data = data, data.count > 2_000_000 {
            return await lessThanTwoMegabyteImage(image: image, quality: max(1, quality - 40.0))
        }
        return data
    }
}

struct ThreadSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSheetView(sheetBinding: .constant(true))
    }
}
