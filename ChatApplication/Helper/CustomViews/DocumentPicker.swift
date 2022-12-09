//
//  DocumentPicker.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/26/21.
//

import MobileCoreServices
import SwiftUI
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileUrl: URL?

    @Binding var showDocumentPicker: Bool

    func updateUIViewController(_: UIViewControllerType, context _: Context) {}

    func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(fileUrl: $fileUrl, showDocumentPicker: $showDocumentPicker)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .plainText, .pdf, .image, .png, .jpeg, .zip], asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: [kUTTypePlainText as String], in: .import)
        }
        picker.delegate = context.coordinator

        return picker
    }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    @Binding var fileUrl: URL?
    @Binding var showDocumentPicker: Bool

    init(fileUrl: Binding<URL?>, showDocumentPicker: Binding<Bool>) {
        _fileUrl = fileUrl
        _showDocumentPicker = showDocumentPicker
    }

    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileUrl = urls.first else { return }
        fileUrl = selectedFileUrl
        showDocumentPicker = false
    }

    func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
        showDocumentPicker = false
    }
}

struct DocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
        DocumentPicker(fileUrl: .constant(URL(string: "")!), showDocumentPicker: .constant(false))
    }
}
