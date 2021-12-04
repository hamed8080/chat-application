//
//  DocumentPicker.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/26/21.
//

import SwiftUI
import UIKit
import MobileCoreServices

struct DocumentPicker: UIViewControllerRepresentable {
 
    @Binding var fileUrl:URL?
    
    @Binding var showDocumentPicker:Bool
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> DocumentPickerCoordinator{
        return DocumentPickerCoordinator(fileUrl:$fileUrl,showDocumentPicker: $showDocumentPicker)
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let picker:UIDocumentPickerViewController
        if #available(iOS 14,*)
        {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .plainText, .pdf,.image,.png,.jpeg,.zip], asCopy: true )
        }else{
            picker = UIDocumentPickerViewController(documentTypes: [kUTTypePlainText as String], in: .import)
        }
        picker.delegate = context.coordinator
        
        return picker
    }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate{
    
    @Binding var fileUrl:URL?
    @Binding var showDocumentPicker:Bool
    
    init(fileUrl:Binding<URL?>, showDocumentPicker:Binding<Bool>){
        _fileUrl = fileUrl
        _showDocumentPicker = showDocumentPicker
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileUrl = urls.first else {return}
        fileUrl = selectedFileUrl
        showDocumentPicker = false
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        showDocumentPicker = false
    }
}

struct DocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
        DocumentPicker(fileUrl: .constant(URL(string: "")!), showDocumentPicker: .constant(false))
    }
}
