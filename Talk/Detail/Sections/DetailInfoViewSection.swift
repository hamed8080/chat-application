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
            let image = viewModel.thread?.computedImageURL ?? viewModel.participantDetailViewModel?.participant.image ?? ""
            let avatarVM = AppState.shared.objectsContainer.threadsVM.avatars(for: image,
                                                                              metaData: viewModel.thread?.metadata,
                                                                              userName: String.splitedCharacter(viewModel.thread?.title ?? ""))
            let config = ImageLoaderConfig(url: image,
                                           metaData: viewModel.thread?.metadata,
                                           userName: String.splitedCharacter(viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name ?? ""))
            let defaultLoader = ImageLoaderViewModel(config: config)
            ImageLoaderView(imageLoader: avatarVM)
                .id("\(image)\(viewModel.thread?.id ?? 0)")
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(String.getMaterialColorByCharCode(str: viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name ?? ""))
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
                        defaultLoader.fetch()
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                let threadName = viewModel.participantDetailViewModel?.participant.contactName ?? viewModel.thread?.computedTitle ?? ""
                Text(threadName)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.textPrimary)

                let count = viewModel.threadVM?.participantsViewModel.thread?.participantCount
                if viewModel.thread?.group == true, let countString = count?.localNumber(locale: Language.preferredLocale) {
                    let label = String(localized: .init("Participant"), bundle: Language.preferedBundle)
                    Text("\(label) \(countString)")
                        .font(.iransansCaption3)
                        .foregroundStyle(Color.App.textSecondary)
                }

                if let notSeenString = viewModel.participantDetailViewModel?.notSeenString {
                    let localized = String(localized: .init("Contacts.lastVisited"), bundle: Language.preferedBundle)
                    let formatted = String(format: localized, notSeenString)
                    Text(formatted)
                        .font(.iransansCaption3)
                }
            }
            Spacer()
        }
        .frame(height: 56)
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.all, 16)
        .background(Color.App.dividerPrimary)
    }
}

struct DetailInfoViewSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailInfoViewSection(viewModel: .init())
    }
}
