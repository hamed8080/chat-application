//
//  ThreadViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine
import AVFoundation

class ThreadViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    private (set) var model = ThreadModel()
    private (set) var thread:Conversation?
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    private (set) var messageCancelable:AnyCancellable? = nil
    private (set) var systemMessageCancelable:AnyCancellable? = nil
    private var typingTimerStarted = false
    
    init(){
        messageCancelable = NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap{$0.object as? MessageEventModel}
            .sink { messageEvent in
                if messageEvent.type == .MESSAGE_NEW , let message = messageEvent.message, self.model.isViewDisplaying{
                    self.model.appendMessage(message)
                }
            }
        systemMessageCancelable = NotificationCenter.default.publisher(for: SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME)
            .compactMap{$0.object as? SystemEventModel}
            .sink { systemMessageEvent in
                if systemMessageEvent.type == .IS_TYPING && systemMessageEvent.threadId == self.thread?.id , self.typingTimerStarted == false{
                    self.typingTimerStarted = true
                    "typing".isTypingAnimationWithText { startText in
                        self.model.setSignalMessage(text: startText)
                    } onChangeText: { text, timer in
                        self.model.setSignalMessage(text: text)
                    } onEnd: {
                        self.typingTimerStarted = false
                        self.model.setSignalMessage(text: nil)
                    }
                }
                if systemMessageEvent.type != .IS_TYPING{
                    String().getSystemTypeString(type: systemMessageEvent.type)?.signalMessage(signal: systemMessageEvent.type, onStart: { startText in
                        self.model.setSignalMessage(text: startText)
                    }, onChangeText: { text, timer in
                        self.model.setSignalMessage(text: text)
                    }, onEnd: {
                        self.model.setSignalMessage(text: nil)
                    })
                }
            }        
    }
    
    //when viewAppreaed this method called and now we can start to retreive thread message
    func setThread(thread:Conversation){
        if self.thread != nil {return}//this mean it's setted before and view is reAppearing
        self.thread = thread
        getMessagesHistory()
    }
    
    func loadMore(){
        if !model.hasNext() || isLoading{return}
        isLoading = true
        model.preparePaginiation()
        getMessagesHistory()
    }
    
    func getMessagesHistory(){
        guard let threadId = thread?.id else{return}
        Chat.sharedInstance.getHistory(.init(threadId: threadId, count:model.count,offset: model.offset)) {[weak self] messages, uniqueId, pagination, error in
            if let messages = messages{
                self?.model.appendMessages(messages: messages)
                self?.isLoading = false
            }
        }cacheResponse: { [weak self] messages, uniqueId, error in
            if let messages = messages{
                self?.model.setMessages(messages: messages)
            }
        }
    }
    
    func refresh() {
        clear()
        getMessagesHistory()
    }
    
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
        model.setupPreview()
    }
    
	func pinUnpinMessage(_ message:Message){
		guard let id = message.id else{return}
		if message.pinned == false{
			Chat.sharedInstance.pinMessage(.init(messageId: id)) { messageId, uniqueId, error in
				if error == nil && messageId != nil{
					self.model.pinMessage(message)
				}
			}
		}else{
			Chat.sharedInstance.unpinMessage(.init(messageId: id)) { messageId, uniqueId, error in
				if error == nil && messageId != nil{
					self.model.unpinMessage(message)
				}
			}
		}
	}
	
    func deleteMessage(_ message:Message){
        guard let messageId = message.id else {return}
        Chat.sharedInstance.deleteMessage(.init(messageId: messageId)) { deletedMessage, uniqueId, error in
            self.model.deleteMessage(message)
        }
	}
    
    func deleteMessageFromModel(_ message:Message){
        self.model.deleteMessage(message)
    }
    
    func clearCacheFile(message:Message){
        if let metadata = message.metadata?.data(using: .utf8), let fileHashCode = try? JSONDecoder().decode(FileMetaData.self, from: metadata).fileHash{
            CacheFileManager.sharedInstance.deleteImageFromCache(fileHashCode: fileHashCode)
        }
    }
    
    func sendTextMessage(_ textMessage:String){
        guard let threadId = thread?.id else {return}
        let req = NewSendTextMessageRequest(threadId: threadId,
                                            textMessage: textMessage,
                                            messageType: .TEXT)
        Chat.sharedInstance.sendTextMessage(req) { uniqueId in
            
        } onSent: { response, uniqueId, error in
            
        } onSeen: { response, uniqueId, error in
            
        } onDeliver: { response, uniqueId, error in
            
        }
    }
    
    func setViewAppear(appear:Bool){
        model.setViewAppear(appear: appear)
    }
        
    func textChanged(_ newValue:String){
        if newValue.isEmpty == false, let threadId = thread?.id{
            Chat.sharedInstance.snedStartTyping(threadId: threadId)
        }else{
            Chat.sharedInstance.sendStopTyping()
        }
    }
    
    func searchInsideThreadMessages(_ text:String){
        //-FIXME: add when merger with serach branch
//        Chat.sharedInstance.searchThread
    }
    
    func muteUnMute(){
        guard let threadId = thread?.id else {return}
        if thread?.mute == false{
            Chat.sharedInstance.muteThread(.init(threadId: threadId)) { threadId, uniqueId, error in
                
            }
        }else{
            Chat.sharedInstance.unmuteThread(.init(threadId: threadId)) { threadId, uniqueId, error in
                
            }
        }
    }
    
    func sendSeenMessageIfNeeded(_ message:Message){
        guard let messageId = message.id else{return}
        if let lastMsgId = thread?.lastSeenMessageId , messageId > lastMsgId{
            Chat.sharedInstance.seen(.init(messageId: messageId))
            //update cache read count
//            CacheFactory.write(cacheType: .THREADS([thread]))
        }
        
    }
    
    func sendPhotos(uiImage:UIImage?, info:[AnyHashable:Any]?, item:ImageItem, textMessage:String = ""){
        guard let image = uiImage, let threadId = thread?.id else{return}
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let message = NewSendTextMessageRequest(threadId: threadId, textMessage: textMessage, messageType: .POD_SPACE_PICTURE)
        let fileName = item.phAsset.originalFilename
        let imageRequest = NewUploadImageRequest(data: image.jpegData(compressionQuality: 1.0) ?? Data(),
                                                 hC: height,
                                                 wC: width,
                                                 fileName: fileName,
                                                 mimeType: "image/jpg",
                                                 userGroupHash: thread?.userGroupHash)
        Chat.sharedInstance.sendFileMessage(textMessage:message, uploadFile: imageRequest){ uploadFileProgress ,error in
            print(uploadFileProgress ?? error ?? "")
        }onSent: { sentResponse, uniqueId, error in
            print(sentResponse ?? "")
        }onSeen: { seenResponse, uniqueId, error in
            print(seenResponse ?? "")
        }onDeliver: { deliverResponse, uniqueId, error in
            print(deliverResponse ?? "")
        }uploadUniqueIdResult:{ uploadUniqueId in
            print(uploadUniqueId)
        }messageUniqueIdResult:{ messageUniqueId in
           print(messageUniqueId)
        }
    }
    
    ///add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    func sendFile(selectedFileUrl:URL, textMessage:String = ""){
        model.appendMessage(UploadFileMessage(uploadFileUrl: selectedFileUrl, textMessage: textMessage))
    }
    
    func toggleRecording(){
        model.toggleIsRecording()
        if model.isRecording{
            startRecording()
        }else{
            stopRecording()
        }
    }
    
    var audioRecorder:AVAudioRecorder? = nil
    func startRecording(){
        sendSignal(.RECORD_VOICE)
        guard let audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("recording.m4a") else {return}
        do {
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
        }catch{
            stopRecording()
        }
    }
    
    func stopRecording(){
        audioRecorder?.stop()
        audioRecorder = nil
        if let audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("recording.m4a"),FileManager.default.fileExists(atPath: audioFilename.path){
            sendFile(selectedFileUrl: audioFilename)
        }
    }
    
    func getPermissionForRecordAudio(){
        do{
            let recordingSession = AVAudioSession.sharedInstance()
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
            }
        }catch{
            print("error to get recording permission")
        }
    }
    
    func sendSignal(_ signalMessage:SignalMessageType){
        guard let threadId = thread?.id else{ return }
        Chat.sharedInstance.newSendSignalMessage(req: .init(signalType: signalMessage , threadId:threadId))
    }
    
    func playAudio(){
        
    }
}
 
