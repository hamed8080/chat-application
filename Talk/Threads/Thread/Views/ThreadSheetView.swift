//
//  ThreadSheetView.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadSheetView: View {
    private var viewModel: ThreadViewModel? { actionSheetViewModel.threadViewModel }
    @EnvironmentObject var actionSheetViewModel: ActionSheetViewModel
    @Binding var sheetBinding: Bool

    var body: some View {
        if let viewModel {
            switch viewModel.sheetType {
            case .attachment:
                EmptyView()
            case .dropItems:
                DropItemsView()
                    .environmentObject(viewModel)
                    .onAppear {
                        actionSheetViewModel.oneTimeSetup()
                    }
                    .onDisappear {
                        viewModel.exportMessagesVM?.deleteFile()
                        viewModel.dropItems.removeAll()
                        closeSheet()
                    }
            case .datePicker:
                DateSelectionView(showDialog: $sheetBinding) { startDate, endDate in
                    viewModel.sheetType = nil
                    viewModel.setupExportMessage(startDate: startDate, endDate: endDate)
                }
                .onDisappear {
                    closeSheet()
                }
            case .exportMessagesFile:
                if let exportFileUrl = viewModel.exportMessagesVM?.filePath {
                    ActivityViewControllerWrapper(activityItems: [exportFileUrl])
                        .onDisappear {
                            viewModel.exportMessagesVM = nil
                            closeSheet()
                        }
                } else {
                    EmptyView()
                }
            case .threadPicker:
                SelectConversationOrContactList { (conversation, contact) in
                    viewModel.sendForwardMessage(conversation, contact)
                }
                .onDisappear {
                    closeSheet()
                }
            case .filePicker:
                DocumentPicker { urls in
                    actionSheetViewModel.selectedFileUrls = urls
                    viewModel.sheetType = nil
                    viewModel.animateObjectWillChange()
                }
                .onAppear {
                    actionSheetViewModel.oneTimeSetup()
                }
                .onDisappear {
                    closeSheet()
                }
            case .locationPicker:
                MapPickerView()
                    .environmentObject(viewModel)
                    .onDisappear {
                        closeSheet()
                    }
            case .galleryPicker:
                GalleryImagePicker(viewModel: actionSheetViewModel)
                    .environmentObject(viewModel)
                    .onAppear {
                        actionSheetViewModel.oneTimeSetup()
                    }
                    .onDisappear {
                        closeSheet()
                    }
            default:
                Text("Sheet \(viewModel.sheetType.debugDescription) not implemented yet.")
            }
        }
    }

    private func closeSheet() {
        sheetBinding = false
        viewModel?.sheetType = nil
        viewModel?.animateObjectWillChange()
    }
}

struct ThreadSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSheetView(sheetBinding: .constant(true))
    }
}
