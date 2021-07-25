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

struct WebRTCView:UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context)-> WebRTCViewController {
        let vc = UIStoryboard(name: "WebRTC", bundle: nil).instantiateInitialViewController() as! WebRTCViewController
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class WebRTCViewController: UIViewController, WebRTCClientDelegate{
  
    
    @IBOutlet weak var localView: UIView!
    var webRTCClient:WebRTCClient?
    private var localRenderer:RTCVideoRenderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let iceServers = ["stun:stun.l.google.com:19302",
                          "stun:stun1.l.google.com:19302",
                          "stun:stun2.l.google.com:19302",
                          "stun:stun3.l.google.com:19302",
                          "stun:stun4.l.google.com:19302"]

        let config = WebRTCConfig(socketSignalingAddress: "ws://192.168.1.15:8080",
                                  iceServers: iceServers,
                                  videoTrack: true,
                                  audioTrack: false,
                                  dataChannel: false,
                                  customFrameCapturer: false,
                                  turnServerAddress: nil,
                                  videoConfig: nil)
        webRTCClient = WebRTCClient(config: config, delegate: self)
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
        
    }
    
    func didDisconnectWebRTC() {
        
    }
    
}
