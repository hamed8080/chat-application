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
    var webRTCClient:WebRTCClientNew?
    private var localRenderer:RTCVideoRenderer?
    
    let isClientA = false
    
    func getConfig()->WebRTCConfig {
        return WebRTCConfig(peerName:"KuretoAdmin2",
                                  iceServers: ["stun:46.32.6.188:3478","turn:46.32.6.188:3478"],
                                  turnAddress: "46.32.6.188:3478",
                                  topicSend: isClientA ? "Vi-hossein" : "Vi-masoud",
                                  topicReceive: isClientA ? "Vi-masoud" : "Vi-hossein",
                                  brokerAddressWeb: "10.56.16.53:9093",
                                  dataChannel: false,
                                  customFrameCapturer: false,
                                  userName: "mkhorrami",
                                  password: "mkh_123456",
                                  videoConfig: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,selector: #selector(self.connectedToSokect),name: CONNECT_NAME, object: nil)
        self.view.subviews.forEach{ view in
            view.isUserInteractionEnabled = false
            view.alpha = 0.5
        }
    }
    
    @objc func connectedToSokect(){
        
        self.view.subviews.forEach{ view in
            view.isUserInteractionEnabled = true
            view.alpha = 1
        }
        if webRTCClient != nil {return}
        webRTCClient = WebRTCClientNew(config: getConfig(), delegate: self)
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
//        self.webRTCClient?.renderRemoteVideo(remoteRenderer)
        remoteRenderer.frame.origin = .zero //to fit to local view position
        self.view.addSubview(remoteRenderer)
        view.sendSubviewToBack(remoteRenderer)
    }
    
    @objc func switchCamera(){
        guard let renderer = localRenderer else {return}
        webRTCClient?.switchCameraPosition(renderer: renderer)
    }
    
    //webrtc signaling nodejs - app test
    
    //never re run app when call is open must tap on close
    @IBAction func stopTaped(_ senderf:UIButton){
        Chat.sharedInstance.closeSignalingServerCall(peerName: getConfig().peerName) //free call for token user
    }
    
    @IBAction func fullOfferTaped(_ senderf:UIButton){
        offerVideoTaped(UIButton())
        offerAudioTaped(UIButton())
    }
    
    @IBAction func offerVideoTaped(_ senderf:UIButton){
//        webRTCClient?.getLocalSDPWithOffer(topic:getConfig().topicVideoSend!,onSuccess: { sdp in
//            self.webRTCClient?.sendOfferToPeer(sdp ,topic: self.getConfig().topicVideoSend! ,mediaType: .VIDEO)
//        })
//
//        webRTCClient?.getLocalSDPWithOffer(topic:getConfig().topicVideoReceive! ,onSuccess: { sdp in
//            self.webRTCClient?.sendOfferToPeer(sdp , topic: self.getConfig().topicVideoReceive!,mediaType: .VIDEO)
//        })
    }
    
    @IBAction func offerAudioTaped(_ senderf:UIButton){
//        webRTCClient?.getLocalSDPWithOffer(topic:getConfig().topicAudioSend!,onSuccess: { sdp in
//            self.webRTCClient?.sendOfferToPeer(sdp , topic: self.getConfig().topicAudioSend! ,mediaType: .AUDIO)
//        })
//
//        webRTCClient?.getLocalSDPWithOffer(topic:getConfig().topicAudioReceive! ,onSuccess: { sdp in
//            self.webRTCClient?.sendOfferToPeer(sdp , topic: self.getConfig().topicAudioReceive!,mediaType: .AUDIO)
//        })
    }
    
    @IBAction func speakerOnTaped(){
//        webRTCClient?.setSpeaker(on: true)
    }
    
    @IBAction func speakerOffTaped(){
//        webRTCClient?.setSpeaker(on: false)
    }
    
    @IBAction func answerTaped(_ senderf:UIButton){
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
