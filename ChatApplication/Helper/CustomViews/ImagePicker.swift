//
//  ImagePicker.swift
//  ChatApplication
//
//  Created by hamed on 2/20/22.
//

import Foundation
import PhotosUI
import SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage, [PHAssetResource]?) -> Void

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding private var presentationMode: PresentationMode
        private let sourceType: UIImagePickerController.SourceType
        private let onImagePicked: (UIImage, [PHAssetResource]?) -> Void

        init(presentationMode: Binding<PresentationMode>, sourceType: UIImagePickerController.SourceType, onImagePicked: @escaping (UIImage, [PHAssetResource]?) -> Void) {
            _presentationMode = presentationMode
            self.sourceType = sourceType
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
        {
            guard let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
            var assetResource: [PHAssetResource]?
            if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                assetResource = PHAssetResource.assetResources(for: asset)
            }

            onImagePicked(uiImage, assetResource)
            presentationMode.dismiss()
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            presentationMode.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(presentationMode: presentationMode,
                    sourceType: sourceType,
                    onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: UIViewControllerRepresentableContext<ImagePicker>) {}
}
