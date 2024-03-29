//
//  DocumentPicker.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/26/21.
//

import MobileCoreServices
import SwiftUI
import UIKit

public struct DocumentPicker: UIViewControllerRepresentable {
    var completionHandler: ([URL]) -> Void

    public init(completionHandler: @escaping ([URL]) -> Void) {
        self.completionHandler = completionHandler
    }

    public func updateUIViewController(_: UIViewControllerType, context _: Context) {}

    public func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(completionHandler: completionHandler)
    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .plainText, .pdf, .image, .png, .jpeg, .zip], asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: [kUTTypePlainText as String], in: .import)
        }
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator

        return picker
    }
}

public final class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    var completionHandler: ([URL]) -> Void

    public init(completionHandler: @escaping ([URL]) -> Void) {
        self.completionHandler = completionHandler
    }

    public func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completionHandler(urls)
    }

    public func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
        completionHandler([])
    }
}

struct DocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
        DocumentPicker { _ in
        }
    }
}
