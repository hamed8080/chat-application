import Chat
import ChatDTO

public protocol UploadWithTextMessageProtocol {
    var sendTextMessageRequest: SendTextMessageRequest? { get set }
    var uploadFileRequest: UploadFileRequest? { get set }
    var uploadImageRequest: UploadImageRequest? { get set }
}
