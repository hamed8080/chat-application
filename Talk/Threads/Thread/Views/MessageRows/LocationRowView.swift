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

final class LocationRowView: UIView {
    private let imageView = UIImageView()
    private let gradient = CAGradientLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        gradient.cornerRadius = 8
        gradient.colors = [Color.App.bgPrimaryUIColor!.cgColor, Color.App.bgPrimaryUIColor?.cgColor ?? UIColor.black.cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 400),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if !viewModel.isMapType { return }
        if let mapImage = viewModel.downloadFileVM?.fileURL?.imageScale(width: Int(800))?.image {
            imageView.image = UIImage(cgImage: mapImage)
        } else {
            imageView.image = UIImage(named: "empty_image")
            layer.insertSublayer(gradient, at: 0)
            setNeedsLayout()
        }

        let canShow = viewModel.isMapType
        isHidden = !canShow
        heightAnchor.constraint(equalToConstant: canShow ? 400 : 0).isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = imageView.frame
    }
}

struct LocationRowViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = LocationRowView()
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
