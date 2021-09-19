//
//  RTCVideoReperesentable.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/19/21.
//

import SwiftUI
import WebRTC

struct RTCVideoReperesentable:UIViewRepresentable {
    
    #if arch(arm64)
        // Using metal (arm64 only)
    let renderer = RTCMTLVideoView(frame: .zero)
    #else
        // Using OpenGLES for the rest
    let renderer = RTCEAGLVideoView(frame: .zero)
    #endif
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        #if arch(arm64)
        renderer.videoContentMode = .scaleAspectFill
        #endif
        
        renderer.frame = view.frame
        renderer.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)//mirror view to show correct
        renderer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(renderer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
