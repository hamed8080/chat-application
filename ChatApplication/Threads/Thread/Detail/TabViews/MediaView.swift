//
//  MediaView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import SwiftUI
import FanapPodChatSDK

struct MediaView: View {
    
    var thread:Conversation
    
    @StateObject
    var viewModel:AttachmentsViewModel = AttachmentsViewModel()
    
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        List{
            LazyVGrid(columns: columns, alignment: .center, spacing: 4){
                ForEach(viewModel.model.messages, id:\.id){ picture in
                    item(picture: picture)
                        .onAppear {
                            if viewModel.model.messages.last == picture{
                                viewModel.loadMore()
                            }
                        }
                }
            }
            .noSeparators()
            .listRowBackground(Color.clear)
        }
        .padding(8)
        .onAppear {
            viewModel.thread = thread
            viewModel.getPictures()
        }
    }
    
    @ViewBuilder
    func item(picture:Message)-> some View{
        if let link = picture.metaData?.file?.link{
            Avatar(url: link,
                   userName: nil,
                   fileMetaData: picture.metadata,
                   style: .init(cornerRadius:-1, size: (UIScreen.main.bounds.width / CGFloat(columns.count)) - 16)
            )
        }
    }
}

class AttachmentsViewModel: ObservableObject{
    
    var thread:Conversation? = nil
    
    @Published
    var isLoading = false
    
    
    @Published
    var model = AttachmentModel()
    
    func getPictures(){
        guard let threadId = thread?.id else {return}
        
        Chat.sharedInstance.getHistory(.init(threadId: threadId, count:model.count, messageType: MessageType.POD_SPACE_PICTURE.rawValue, offset: model.offset)) {[weak self] messages, uniqueId, pagination, error in
            if let messages = messages{
                self?.model.appendMessages(messages: messages)
                self?.model.setContentCount(totalCount: pagination?.totalCount ?? 0 )
            }
            self?.isLoading = false
        }cacheResponse: { [weak self] messages, uniqueId, error in
            if let messages = messages{
                self?.model.setMessages(messages: messages)
            }
        }
    }
    
    func loadMore(){
        if !model.hasNext() || isLoading{return}
        isLoading = true
        model.preparePaginiation()
        getPictures()
    }
}


struct AttachmentModel {
    
    private (set) var count                         = 50
    private (set) var offset                        = 0
    private (set) var totalCount                    = 0
    private (set) var messages :[Message]           = []
    
    func hasNext()->Bool{
        return messages.count < totalCount
    }
    
    mutating func preparePaginiation(){
        offset = messages.count
    }
    
    mutating func setContentCount(totalCount:Int){
        self.totalCount = totalCount
    }
    
    mutating func setMessages(messages:[Message]){
        self.messages = messages
        sort()
    }
    
    mutating func appendMessages(messages:[Message]){
        self.messages.append(contentsOf: filterNewMessagesToAppend(serverMessages: messages))
        sort()
    }
    
    /// Filter only new messages prevent conflict with cache messages
    mutating func filterNewMessagesToAppend(serverMessages:[Message])->[Message]{
        let ids = self.messages.map{$0.id}
        let newMessages = serverMessages.filter { message in
            !ids.contains { id in
                return id == message.id
            }
        }
        return newMessages
    }
    
    mutating func appendMessage(_ message:Message){
        self.messages.append(message)
        sort()
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.totalCount = 0
        self.messages   = []
    }
    
    mutating func sort(){
        messages = messages.sorted { m1, m2 in
            if let t1 = m1.time , let t2 = m2.time{
                return t1 < t2
            }else{
                return false
            }
        }
    }
}

struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        MediaView(thread: MockData.thread)
    }
}
