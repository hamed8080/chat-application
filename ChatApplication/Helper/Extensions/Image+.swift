//
//  Image+.swift
//  ChatApplication
//
//  Created by hamed on 12/30/22.
//

import SwiftUI

extension Image {
    init(cgImage: CGImage) {
        self = Image(uiImage: UIImage(cgImage: cgImage))
    }
}
