//
//  DetailInfoViewSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
import TalkModels
import TalkUI
import Chat

struct DetailInfoViewSection: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @StateObject private var fullScreenImageLoader: ImageLoaderViewModel

    init(viewModel: ThreadDetailViewModel) {
        let config = ImageLoaderConfig(url: viewModel.thread?.computedImageURL ?? "",
                                       size: .ACTUAL,
                                       metaData: viewModel.thread?.metadata,
                                       userName: String.splitedCharacter(viewModel.thread?.title ?? ""),
                                       forceToDownloadFromServer: true)
        self._fullScreenImageLoader = .init(wrappedValue: .init(config: config))
    }

    var body: some View {
        HStack(spacing: 16) {
            imageView
            VStack(alignment: .leading, spacing: 4) {
                threadTitle
                participantsCount
                lastSeen
            }
            Spacer()
        }
        .frame(height: 56)
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.all, 16)
        .background(Color.App.dividerPrimary)
    }


    private var imageLink: String {
        viewModel.thread?.computedImageURL ?? viewModel.participantDetailViewModel?.participant.image ?? ""
    }

    private var imageVM: ImageLoaderViewModel {
        let config = ImageLoaderConfig(url: imageLink,
                                       metaData: viewModel.thread?.metadata,
                                       userName: String.splitedCharacter(viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name ?? ""))
        let defaultLoader = ImageLoaderViewModel(config: config)
        return defaultLoader
    }

    private var avatarVM: ImageLoaderViewModel {
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let avatarVM = threadsVM.avatars(for: imageLink, metaData: viewModel.thread?.metadata, userName: String.splitedCharacter(viewModel.thread?.title ?? ""))
        return avatarVM
    }

    @ViewBuilder
    private var imageView: some View {
        ImageLoaderView(imageLoader: avatarVM)
            .id("\(imageLink)\(viewModel.thread?.id ?? 0)")
            .font(.system(size: 16).weight(.heavy))
            .foregroundColor(.white)
            .frame(width: 64, height: 64)
//            .background(String.getMaterialColorByCharCode(str: viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name ?? ""))
            .clipShape(RoundedRectangle(cornerRadius:(28)))
            .overlay {
                if viewModel.thread?.type == .selfThread {
                    SelfThreadImageView(imageSize: 64, iconSize: 28)
                }
            }
            .onTapGesture {
                fullScreenImageLoader.fetch()
            }
            .onReceive(fullScreenImageLoader.$image) { newValue in
                if newValue.size.width > 0 {
                    appOverlayVM.galleryImageView = newValue
                }
            }
            .onReceive(NotificationCenter.thread.publisher(for: .thread)) { notification in
                if let threadEvent = notification.object as? ThreadEventTypes, case .updatedInfo(_) = threadEvent {
                    imageVM.fetch()
                }
            }
    }

    private var threadTitle: some View {
        HStack {
            let threadName = viewModel.participantDetailViewModel?.participant.contactName ?? viewModel.thread?.computedTitle ?? ""
            Text(threadName)
                .font(.iransansBody)
                .foregroundStyle(Color.App.textPrimary)

            if viewModel.thread?.isTalk == true {
                Image("ic_approved")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .offset(x: -4)
            }
        }
    }

    @ViewBuilder
    private var participantsCount: some View {
        let count = viewModel.threadVM?.participantsViewModel.thread?.participantCount
        if viewModel.thread?.group == true, let countString = count?.localNumber(locale: Language.preferredLocale) {
            let label = String(localized: .init("Thread.Toolbar.participants"), bundle: Language.preferedBundle)
            Text(verbatim: "\(countString) \(label)")
                .font(.iransansCaption3)
                .foregroundStyle(Color.App.textSecondary)
        }
    }

    @ViewBuilder
    private var lastSeen: some View {
        if let notSeenString = viewModel.participantDetailViewModel?.notSeenString {
            let localized = String(localized: .init("Contacts.lastVisited"), bundle: Language.preferedBundle)
            let formatted = String(format: localized, notSeenString)
            Text(formatted)
                .font(.iransansCaption3)
        }
    }
}

struct DetailInfoViewSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailInfoViewSection(viewModel: .init())
    }
}
