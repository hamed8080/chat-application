//
//  ThreadSheetView.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import ChatAppUI
import ChatAppViewModels
import SwiftUI

struct ThreadSheetView: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @EnvironmentObject var actionSheetViewModel: ActionSheetViewModel
    @Binding var sheetBinding: Bool

    var body: some View {
        let type = viewModel.sheetType
        switch type {
        case .attachment:
            AttachmentDialog(viewModel: actionSheetViewModel)
        case .dropItems:
            DropItemsView()
                .animation(.easeInOut, value: viewModel.dropItems.count)
                .environmentObject(viewModel)
        case .datePicker:
            DateSelectionView(showDialog: $sheetBinding) { startDate, endDate in
                viewModel.sheetType = nil
                viewModel.exportMessagesVM.exportChats(startDate: startDate, endDate: endDate)
            }
        case .exportMessagesFile:
            if let exportFileUrl = viewModel.exportMessagesVM.filePath {
                ActivityViewControllerWrapper(activityItems: [exportFileUrl])
            } else {
                EmptyView()
            }
        case .threadPicker:
            SelectThreadContentList { selectedThread in
                viewModel.sendForwardMessage(selectedThread)
            }
        case .filePicker:
            DocumentPicker { urls in
                actionSheetViewModel.selectedFileUrls = urls
                viewModel.sheetType = nil
            }
        case .locationPicker:
            MapPickerView()
        default:
            Text("Sheet \(viewModel.sheetType.debugDescription) not implemented yet.")
        }
    }
}

struct ThreadSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSheetView(sheetBinding: .constant(true))
    }
}
