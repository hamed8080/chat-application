//
//  ThreadSheetView.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkUI
import TalkViewModels

/// We have to use this due to in the ThreadView we used let viewModel in it will never trigger the sheet.
struct SheetEmptyBackground: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    var sheetBinding: Binding<Bool> { Binding(get: { viewModel.sheetType != nil }, set: { _ in }) }

    var body: some View {
        Color.clear
            .sheet(isPresented: sheetBinding) {
                ThreadSheetView(sheetBinding: sheetBinding)
                    .environmentObject(viewModel.attachmentsViewModel)
            }
    }
}

struct ThreadSheetView: View {
    private var viewModel: ThreadViewModel? { attachmentsViewModel.threadViewModel }
    @EnvironmentObject var attachmentsViewModel: AttachmentsViewModel
    @Binding var sheetBinding: Bool

    var body: some View {
        if let viewModel {
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
                    viewModel.openDestinationConversationToForward(conversation, contact)
                }
                .onDisappear {
                    closeSheet()
                }
            case .filePicker:
                DocumentPicker { urls in
                    attachmentsViewModel.selectedFileUrls = urls
                    viewModel.sheetType = nil
                    viewModel.animateObjectWillChange()
                }
                .onAppear {
                    attachmentsViewModel.oneTimeSetup()
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
                GalleryImagePicker(viewModel: attachmentsViewModel)
                    .environmentObject(viewModel)
                    .onAppear {
                        attachmentsViewModel.oneTimeSetup()
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
