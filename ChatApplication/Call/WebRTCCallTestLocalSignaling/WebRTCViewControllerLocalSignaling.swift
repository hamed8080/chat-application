//
//  WebRTCViewController.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/3/21.
//


import Foundation
import UIKit
import FanapPodChatSDK
import SwiftUI
import WebRTC

struct WebRTCViewLocalSignalingView:UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context)-> WebRTCViewControllerLocalSignaling {
        let vc = UIStoryboard(name: "WebRTCLocalSignaling", bundle: nil).instantiateInitialViewController() as! WebRTCViewControllerLocalSignaling
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class WebRTCViewControllerLocalSignaling: UIViewController, WebRTCClientDelegate{
    
    @IBOutlet weak var localView: UIView!
    var webRTCClient:WebRTCClientNewLocalSignaling?
    private var localRenderer:RTCVideoRenderer?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.subviews.forEach{ view in
            view.isUserInteractionEnabled = false
            view.alpha = 0.5
        }
        webRTCClient = WebRTCClientNewLocalSignaling(delegate: self)
        #if arch(arm64)
            // Using metal (arm64 only)
            let localRenderer = RTCMTLVideoView(frame: self.localView?.frame ?? CGRect.zero)
            let remoteRenderer = RTCMTLVideoView(frame: self.view.frame)
            localRenderer.videoContentMode = .scaleAspectFill
            remoteRenderer.videoContentMode = .scaleAspectFill
        #else
            // Using OpenGLES for the rest
            let localRenderer = RTCEAGLVideoView(frame: self.localView?.frame ?? CGRect.zero)
            let remoteRenderer = RTCEAGLVideoView(frame: self.view.frame)
        #endif
        
        //setup local camera view
        localView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)//mirror view to show correct posiotion on view
        self.localRenderer = localRenderer
        self.webRTCClient?.startCaptureLocalVideo(renderer: localRenderer)
        localRenderer.frame.origin = .zero //to fit to local view position
        localView.addSubview(localRenderer)
        localView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(switchCamera)))

        //setup remote camera view
        self.webRTCClient?.renderRemoteVideo(remoteRenderer)
        remoteRenderer.frame.origin = .zero //to fit to local view position
        self.view.addSubview(remoteRenderer)
        view.sendSubviewToBack(remoteRenderer)
    }
    
    @objc func switchCamera(){
        guard let renderer = localRenderer else {return}
        webRTCClient?.switchCameraPosition(renderer: renderer)
    }
    
    @IBAction func offerTaped(_ senderf:UIButton){
        webRTCClient?.getLocalSDPWithOffer(onSuccess: { sdp in
            self.webRTCClient?.sendOfferToPeer(sdp)
        })
    }
    
    @IBAction func answerTaped(_ senderf:UIButton){
        webRTCClient?.getAnswerSDP(onSuccess: { sdp in
            self.webRTCClient?.sendAnswerToPeer(sdp)
        })
    }
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        
    }
    
    func didReceiveData(data: Data) {
        
    }
    
    func didReceiveMessage(message: String) {
        
    }
    
    func didConnectWebRTC() {
        self.view.subviews.forEach{ view in
            view.isUserInteractionEnabled = true
            view.alpha = 1
        }
    }
    
    func didDisconnectWebRTC() {
        
    }
    
}
