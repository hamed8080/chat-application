//
//  ImageLoaderView.swift
//  TalkUI
//
//  Created by hamed on 1/18/23.
//

import Chat
import Foundation
import SwiftUI
import TalkModels
import TalkViewModels
import ChatDTO
import Combine

public struct ImageLoaderView: View {
    @StateObject var imageLoader: ImageLoaderViewModel
    let contentMode: ContentMode
    let textFont: Font

    public init(imageLoader: ImageLoaderViewModel,
                contentMode: ContentMode = .fill,
                textFont: Font = .iransansBody
    ) {
        self.textFont = textFont
        self.contentMode = contentMode
        self._imageLoader = StateObject(wrappedValue: imageLoader)
    }

    public var body: some View {
        ZStack {
            if !imageLoader.isImageReady {
                Text(String(imageLoader.config.userName ?? " "))
                    .font(textFont)
            } else if imageLoader.isImageReady {
                Image(uiImage: imageLoader.image)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .animation(.easeInOut, value: imageLoader.image)
        .animation(.easeInOut, value: imageLoader.isImageReady)
        .onAppear {
            if !imageLoader.isImageReady {
                imageLoader.fetch()
            }
        }
    }
}

public final class ParticipantImageLoaderUIView: UIView {
    public var imageLoaderVM: ImageLoaderViewModel?
    private let participantLabel = UILabel()
    private let imageIconView = UIImageView()
    private var cancelable: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        imageIconView.translatesAutoresizingMaskIntoConstraints = false

        imageIconView.contentMode = .scaleAspectFill

        addSubview(participantLabel)
        addSubview(imageIconView)

        NSLayoutConstraint.activate([
            participantLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            participantLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public func setValues(config: ImageLoaderConfig) {
        if imageLoaderVM == nil {
            imageLoaderVM = .init(.init(config: config))
            setupObserver()
            Task {
                await imageLoaderVM?.fetch()
            }
        }
        participantLabel.text = String(imageLoaderVM?.config.userName?.first ?? " ")
    }

    private func setupObserver() {
        cancelable = imageLoaderVM?.$image.sink { [weak self] _ in
            self?.setImage()
        }
    }

    private func setImage() {
        imageIconView.image = imageLoaderVM?.image
        participantLabel.isHidden = imageLoaderVM?.isImageReady == true    
    }
}

public final class ImageLoaderUIView: UIView {
    public var imageLoaderVM: ImageLoaderViewModel?
    private let imageIconView = UIImageView()
    private var cancelable: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imageIconView.translatesAutoresizingMaskIntoConstraints = false

        imageIconView.contentMode = .scaleAspectFill

        addSubview(imageIconView)

        NSLayoutConstraint.activate([
            imageIconView.topAnchor.constraint(equalTo: topAnchor),
            imageIconView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageIconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageIconView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    public func setValues(config: ImageLoaderConfig) {
        if imageLoaderVM == nil {
            imageLoaderVM = .init(.init(config: config))
            setupObserver()
            Task {
                await imageLoaderVM?.fetch()
            }
        }
    }

    private func setupObserver() {
        cancelable = imageLoaderVM?.$image.sink { [weak self] _ in
            self?.setImage()
        }
    }

    private func setImage() {
        imageIconView.image = imageLoaderVM?.image
    }
}

struct ImageLoaderUIViewWapper: UIViewRepresentable {
    let config: ImageLoaderConfig

    func makeUIView(context: Context) -> some UIView {
        let view = ImageLoaderUIView()
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ImageLoaderView_Previews: PreviewProvider {
    struct Preview: View {
        let config = ImageLoaderConfig(url: "https://media.gcflearnfree.org/ctassets/topics/246/share_size_large.jpg", userName: "Hamed")
        var body: some View {
            ImageLoaderUIViewWapper(config: config)
        }
    }

    static var previews: some View {
        Preview()
    }
}
