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
//struct SheetEmptyBackground: View {
//    @EnvironmentObject var viewModel: ThreadViewModel
//    var sheetBinding: Binding<Bool> { Binding(get: { viewModel.sheetType != nil }, set: { _ in }) }
//
//    var body: some View {
//        Color.clear
//            .sheet(isPresented: sheetBinding) {
//                ThreadSheetView(sheetBinding: sheetBinding)
//                    .environmentObject(viewModel)
//                    .environmentObject(viewModel.attachmentsViewModel)
//            }
//    }
//}

struct ThreadSheetView: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var sheetBinding: Bool

    var body: some View {
        EmptyView()
//        switch viewModel.sheetType {
//        case .attachment:
//            EmptyView()
//        case .datePicker:
//            DateSelectionView(showDialog: $sheetBinding) { startDate, endDate in
//                viewModel.sheetType = nil
//                viewModel.setupExportMessage(startDate: startDate, endDate: endDate)
//            }
//            .onDisappear {
//                closeSheet()
//            }
//        case .exportMessagesFile:
//            if let exportFileUrl = viewModel.exportMessagesViewModel.filePath {
//                ActivityViewControllerWrapper(activityItems: [exportFileUrl])
//                    .onDisappear {
//                        viewModel.exportMessagesViewModel.deleteFile()
//                        closeSheet()
//                    }
//            } else {
//                EmptyView()
//            }
//        case .threadPicker:
//            EmptyView()
//        case .filePicker:
//            EmptyView()
//        case .locationPicker:
//            EmptyView()
//        case .galleryPicker:
//            EmptyView()
//        default:
//            Text("Sheet \(viewModel.sheetType.debugDescription) not implemented yet.")
//        }
    }

    private func closeSheet() {
//        sheetBinding = false
//        viewModel.sheetType = nil
//        viewModel.animateObjectWillChange()
    }
}

struct ThreadSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSheetView(sheetBinding: .constant(true))
    }
}
