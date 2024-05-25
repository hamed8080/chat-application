//
//  CameraCapturer.swift
//  Talk
//
//  Created by hamed on 4/2/24.
//

import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CoreServices

struct CameraCapturer: UIViewControllerRepresentable {
    let isVideo: Bool
    let onImagePicked: (UIImage?, URL?, [PHAssetResource]?) -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = UIImagePickerController()
        vc.delegate = context.coordinator
        vc.sourceType  = .camera
        if isVideo {
            if #available(iOS 15.0, *) {
                vc.mediaTypes = [UTType.movie.identifier]
            } else {
                vc.mediaTypes = [kUTTypeMovie as String]
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage?, URL?, [PHAssetResource]?) -> Void

        public init(onImagePicked: @escaping (UIImage?, URL?, [PHAssetResource]?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            var assetResource: [PHAssetResource]?
            if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                assetResource = PHAssetResource.assetResources(for: asset)
            }
            onImagePicked(uiImage, videoURL, assetResource)
            picker.dismiss(animated: true)
        }
    }
}
