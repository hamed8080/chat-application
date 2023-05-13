//
//  RTCVideoReperesentable.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/19/21.
//

import SwiftUI
import WebRTC

public struct RTCVideoReperesentable: UIViewRepresentable {
    public let renderer: UIView

    public init(renderer: UIView) {
        self.renderer = renderer
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        if TARGET_OS_SIMULATOR != 0 {
            // its simulator
        } else {
            (renderer as! RTCMTLVideoView).videoContentMode = .scaleAspectFit
            (renderer as! RTCMTLVideoView).delegate = context.coordinator
        }
        renderer.frame = view.frame
        renderer.transform = CGAffineTransform(scaleX: -1.0, y: 1.0) // mirror view to show correct
        renderer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(renderer)
        return view
    }

    public func updateUIView(_: UIView, context _: Context) {
//        view.layoutIfNeeded()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator: NSObject, RTCVideoViewDelegate {
        public func videoView(_: RTCVideoRenderer, didChangeVideoSize _: CGSize) {
//            (renderer as? UIView)?.layoutIfNeeded()
        }
    }
}
