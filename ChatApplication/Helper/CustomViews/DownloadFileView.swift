//
//  DownloadFileView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK
import Combine

struct DownloadFileView :View{
    
    @ObservedObject var downloadFile : DownloadFile
    @State var data                  : Data    = Data()
    @State var image                 : UIImage = UIImage()
    @State var percent               : Double  = 0
    private var fileHashCode         : String
    private var isImage              : Bool    = false
    private var message              : Message?
    
    @State
    var shareDownloadedFile          : Bool    = false
    
    init(message:Message, placeHolder:UIImage? = nil, state:DownloadFileState? = nil) {
        self.message = message
        let messageType = MessageType(rawValue: message.messageType ?? 0)
        isImage = messageType == .POD_SPACE_PICTURE || messageType == .PICTURE
        self.fileHashCode = message.metaData?.fileHash ?? ""
        downloadFile = DownloadFile(fileHashCode: fileHashCode, isImage: isImage)
        
        if let placeHolder = placeHolder {
            downloadFile.image = placeHolder
        }

        //only for preveiw
        if let state = state{
            downloadFile.state = state
        }
    }
    
    var body: some View{
        GeometryReader{ reader in
            HStack{
                ZStack(alignment:.center){
                    switch downloadFile.state{
                    case .COMPLETED:
                        if isImage{
                            Image(uiImage: image)
                                .resizable()
                                .cornerRadius(8)
                                .scaledToFit()
                        }else{
                            Image(systemName: message?.iconName ?? "")
                                .resizable()
                                .foregroundColor(Color(named: "text_color_blue").opacity(0.8))
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .onTapGesture {
                                    shareDownloadedFile.toggle()
                                }
                        }
                    case .DOWNLOADING, .STARTED:
                        CircularProgressView(percent: $percent)
                            .padding()
                            .onTapGesture {
                                downloadFile.pauseDownload()
                            }
                    case .PAUSED:
                        Image(systemName: "pause.circle")
                            .resizable()
                            .font(.headline.weight(.thin))
                            .foregroundColor(Color.white)
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .onTapGesture {
                                downloadFile.resumeDownload()
                            }
                    case .UNDEFINED:
                        Rectangle()
                            .fill(Color.blue.opacity(0.5))
                            .blur(radius: 24)
                        
                        Image(systemName: "arrow.down.circle")
                            .resizable()
                            .font(.headline.weight(.thin))
                            .padding(32)
                            .scaledToFit()
                            .foregroundColor(Color.white)
                            .onTapGesture {
                                downloadFile.startDownload()
                            }
                    default:
                        EmptyView()
                    }
                }
            }
            .frame(maxWidth:.infinity, maxHeight: .infinity)
            .onReceive(downloadFile.$data) { data in
                self.data = data ?? Data()
            }
            .onReceive(downloadFile.$image) { image in
                if let image = image{
                    self.image = image
                }
            }
            .onReceive(downloadFile.didChangeProgress) { percent in
                if let percent = percent{
                    self.percent = percent
                }
            }.onAppear {
                downloadFile.getImageIfExistInCache()
            }
            .sheet(isPresented: $shareDownloadedFile, content:{
                if let fileUrl = downloadFile.fileUrl{
                    ActivityViewControllerWrapper(activityItems: [fileUrl])
                }else{
                    EmptyView()
                }
            })
        }
    }
}

enum DownloadFileState{
    case STARTED
    case COMPLETED
    case DOWNLOADING
    case PAUSED
    case ERROR
    case UNDEFINED
}

class DownloadFile: ObservableObject{
    
    private (set) var didChangeProgress             = PassthroughSubject<Double?,Never>()
    @Published var state         :DownloadFileState = .UNDEFINED
    @Published var data          :Data?             = nil
    @Published var image         :UIImage?          = nil
    private var fileHashCode     :String
    private var downloadUniqueId :String?           = nil
    private var isImage          :Bool              = false
    
    init(fileHashCode:String, isImage:Bool = false){
        self.fileHashCode = fileHashCode
        self.isImage      = isImage
        if isImage{
            getImageIfExistInCache()
        }else{
            getFileIfExistInCache()
        }
    }
    
    func startDownload(){
        state = .DOWNLOADING
        if isImage{
            downloadImage()
        }else{
            downloadFile()
        }
    }
    
    func downloadFile(){
        let req = FileRequest(hashCode: fileHashCode,forceToDownloadFromServer: true)
        Chat.sharedInstance.getFile(req: req) { downloadProgress in
            self.didChangeProgress.send(Double(downloadProgress.percent))
        } completion: { data, fileModel, error in
            self.data = data
            if error == nil{
                self.state = .COMPLETED
            }else{
                self.state = .ERROR
            }
        } cacheResponse: { data, fileModel, error in
            if let data = data{
                self.data = data
                self.didChangeProgress.send(100)
                self.state = .COMPLETED
            }
        } uniqueIdResult: { uniqueId in
            self.downloadUniqueId = uniqueId
        }
    }
    
    func downloadImage(){
        let req = ImageRequest(hashCode: fileHashCode, forceToDownloadFromServer: true  , isThumbnail: false , size: .ACTUAL)
        Chat.sharedInstance.getImage(req: req) { downloadProgress in
            self.didChangeProgress.send(Double(downloadProgress.percent))
        } completion: { data, fileModel, error in
            if let data = data, error == nil{
                self.image = UIImage(data: data)
                self.state = .COMPLETED
            }else{
                self.state = .ERROR
            }
        } cacheResponse: { data, fileModel, error in
            if let data = data{
                self.data = data
                self.didChangeProgress.send(100)
                self.state = .COMPLETED
            }
        } uniqueIdResult: { uniqueId in
            self.downloadUniqueId = uniqueId
        }
    }
    
    func getImageIfExistInCache(isThumbnail:Bool = true){
        let req = ImageRequest(hashCode: fileHashCode, forceToDownloadFromServer: false  , isThumbnail: false , size: .ACTUAL)
        Chat.sharedInstance.getImage(req: req) { downloadProgress in
        } completion: { data, fileModel, error in
        } cacheResponse: { data, fileModel, error in
            if let data = data{
                self.state = .COMPLETED
                self.image = UIImage(data: data)
            }
        }
    }
    
    func getFileIfExistInCache(){
        let req = FileRequest(hashCode: fileHashCode, forceToDownloadFromServer: false)
        Chat.sharedInstance.getFile(req: req) { downloadProgress in
        } completion: { data, fileModel, error in
        } cacheResponse: { data, fileModel, error in
            if let data = data{
                self.state = .COMPLETED
                self.data = data
            }
        }
    }
    
    func pauseDownload(){
        guard let downloadUniqueId = downloadUniqueId else {return}
        Chat.sharedInstance.manageDownload(uniqueId: downloadUniqueId, action: .suspend, isImage: true){ statusString, susccessAction in
            self.state = .PAUSED
        }
    }
    
    func resumeDownload(){
        guard let downloadUniqueId = downloadUniqueId else {return}
        Chat.sharedInstance.manageDownload(uniqueId: downloadUniqueId, action: .resume, isImage: true){ statusString, susccessAction in
            self.state = .DOWNLOADING
        }
    }
    
    var fileUrl:URL?{
        return CacheFileManager.sharedInstance.getFileUrl(fileHashCode)
    }
}

struct DownloadFileView_Previews: PreviewProvider {
    
    static var previews: some View {
        DownloadFileView(message: Message(message: "Hello"))
    }
}

