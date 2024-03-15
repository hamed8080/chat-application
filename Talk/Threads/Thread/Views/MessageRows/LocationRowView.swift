//
//  LocationRowView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import ChatModels
import Chat
import TalkModels

final class LocationRowView: UIImageView {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layer.cornerRadius = 8
        layer.masksToBounds = true
        clipsToBounds = true
        contentMode = .scaleAspectFill

        translatesAutoresizingMaskIntoConstraints = false

        gradient.cornerRadius = 8
        gradient.colors = [Color.App.bgPrimaryUIColor!.cgColor, Color.App.bgPrimaryUIColor?.cgColor ?? UIColor.black.cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(lessThanOrEqualToConstant: 320),
        ])
    }

    private func onTap(message: Message) {
        if let url = message.neshanURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let canShow = viewModel.rowType.isMap
        if canShow, let mapImage = viewModel.downloadFileVM?.fileURL?.imageScale(width: Int(800))?.image {
            image = UIImage(cgImage: mapImage)
            layer.opacity = 1.0
        } else if canShow {
            image = UIImage(named: "empty_image")
            layer.insertSublayer(gradient, at: 0)
            layer.opacity = 0.5
        }
        isHidden = !canShow
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = frame
    }

    private func setImage(viewModel: DownloadFileViewModel) {
        if let scaledImage = viewModel.fileURL?.imageScale(width: Int(800))?.image {
            image = UIImage(cgImage: scaledImage)
            layer.opacity = 1.0
        }
    }

    private func manageDownload(viewModel: DownloadFileViewModel) {
        if viewModel.isInCache {
            viewModel.state = .completed
            viewModel.animateObjectWillChange()
        } else {
            viewModel.startDownload()
        }
    }
}

struct LocationRowViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = LocationRowView(frame: .init(origin: .zero, size: .init(width: 64, height: 64)))
        view.set(viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct LocationRowView_Previews: PreviewProvider {
    static var previews: some View {
        let metaData = """
{
          "mapLink" : "https://maps.neshan.org/@35.673379,51.490307",
          "hashCode" : "N899JI19VXN3ABPY",
          "longitude" : 51.490307000000001,
          "fileHash" : "N899JI19VXN3ABPY",
          "file" : {
            "mimeType" : "application/octet-stream",
            "hashCode" : "N899JI19VXN3ABPY",
            "size" : 126314,
            "fileHash" : "N899JI19VXN3ABPY",
            "actualWidth" : 800,
            "actualHeight" : 500,
            "link" : "https://podspace.pod.ir/api/files/N899JI19VXN3ABPY",
            "extension" : "",
            "parentHash" : "6MIPH7UM1P7OIZ2L",
            "originalName" : "موقعیت من",
            "name" : "موقعیت من"
          }
}
"""
        let message = Message(id: 1, messageType: .participantJoin, metadata: metaData, time: 155600555)
        let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        LocationRowViewWapper(viewModel: viewModel)
    }
}
