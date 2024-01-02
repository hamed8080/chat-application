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

//struct LocationRowView: View {
//    @EnvironmentObject var viewModel: MessageRowViewModel
//    var message: Message { viewModel.message }
//    
//    var body: some View {
//        let meta = viewModel.fileMetaData
//        if viewModel.isMapType, let fileLink = meta?.file?.link, let downloadVM = viewModel.downloadFileVM {
//            ZStack {
//                /// We use max to at least have a width, because there are times that maxWidth is nil.
//                let width = max(128, (ThreadViewModel.maxAllowedWidth)) - (18 + MessageRowBackground.tailSize.width)
//                /// We use max to at least have a width, because there are times that maxWidth is nil.
//                /// We use min to prevent the image gets bigger than 320 if it's bigger.
//                let height = min(320, max(128, (ThreadViewModel.maxAllowedWidth)))
//                MapImageDownloader(width: width, height: width)
//                    .id(fileLink)
//                    .environmentObject(downloadVM)
//                    .frame(width: width, height: height)
//                    .clipShape(RoundedRectangle(cornerRadius:(8)))
//            }
//            .onTapGesture {
//                if let url = message.neshanURL, UIApplication.shared.canOpenURL(url) {
//                    UIApplication.shared.open(url)
//                }
//            }
//            .task {
//                if downloadVM.isInCache {
//                    downloadVM.state = .completed
//                    viewModel.animateObjectWillChange()
//                } else {
//                    downloadVM.startDownload()
//                }
//            }
//        }
//    }
//}

//struct MapImageDownloader: View {
//    let width: CGFloat
//    let height: CGFloat
//    @EnvironmentObject var viewModel: DownloadFileViewModel
//
//    var body: some View {
//        if viewModel.state == .completed, let image = viewModel.fileURL?.imageScale(width: Int(800))?.image {
//            Image(uiImage: UIImage(cgImage: image))
//                .resizable()
//                .scaledToFill()
//        } else if let emptyImage = UIImage(named: "empty_image") {
//            Image(uiImage: emptyImage)
//                .resizable()
//                .scaledToFill()
//                .frame(width: width, height: height)
//                .clipped()
//                .zIndex(0)
//                .background(LinearGradient(colors: [Color.App.bgInput, Color.App.bgInputDark], startPoint: .top, endPoint: .bottom))
//                .clipShape(RoundedRectangle(cornerRadius:(8)))
//        }
//    }
//}

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
        gradient.colors = [Color.App.uibgInput!.cgColor, Color.App.uibgInputDark!.cgColor]
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

    public func setValues(viewModel: MessageRowViewModel) {
        if !viewModel.isMapType { return }
        if let mapImage = viewModel.downloadFileVM?.fileURL?.imageScale(width: Int(800))?.image {
            imageView.image = UIImage(cgImage: mapImage)
        } else {
            imageView.image = UIImage(named: "empty_image")
            layer.insertSublayer(gradient, at: 0)
            setNeedsLayout()
        }
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
        view.setValues(viewModel: viewModel)
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
