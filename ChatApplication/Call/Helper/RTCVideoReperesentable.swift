//
//  RTCVideoReperesentable.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/19/21.
//

import SwiftUI
import WebRTC

struct RTCVideoReperesentable:UIViewRepresentable {
    
    let renderer:UIView
    
    init(renderer:UIView){
        self.renderer = renderer
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        #if arch(arm64)
        (renderer as! RTCMTLVideoView).videoContentMode = .scaleAspectFit
        #else
        (renderer as! RTCEAGLVideoView).videoContentMode = .scaleAspectFit
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
