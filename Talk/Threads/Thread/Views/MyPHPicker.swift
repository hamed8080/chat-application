//
//  MyPHPicker.swift
//  Talk
//
//  Created by hamed on 10/18/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import TalkUI
import PhotosUI

public struct MyPHPicker: UIViewControllerRepresentable {
    private let onCompletion: ([NSItemProvider])->()

    public init(onCompletion: @escaping ([NSItemProvider]) -> Void) {
        self.onCompletion = onCompletion
    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        let library = PHPhotoLibrary.shared()
        var config = PHPickerConfiguration(photoLibrary: library)
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .livePhotos, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    public func makeCoordinator() -> MyPHPickerCoordinator {
        return MyPHPickerCoordinator(onCompletion: onCompletion)
    }

    public class MyPHPickerCoordinator: NSObject, PHPickerViewControllerDelegate {
        private let onCompletion: ([NSItemProvider])->()

        public init(onCompletion: @escaping ([NSItemProvider]) -> Void) {
            self.onCompletion = onCompletion
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            let itemProviders = results.map(\.itemProvider)
            onCompletion(itemProviders)
        }
    }
}

struct MyPHPicker_Previews: PreviewProvider {
    static var previews: some View {
        MyPHPicker { _ in }
    }
}
