//
//  EditGroup.swift
//  Talk
//
//  Created by hamed on 10/20/23.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct EditGroup: View {
    @EnvironmentObject var viewModel: DetailViewModel

    enum EditGroupFocusFields: Hashable {
        case name
        case description
    }

    @FocusState var focusState: EditGroupFocusFields?
    @State var showImagePicker: Bool = false

    var body: some View {
        List {
            HStack{
                Spacer()

                Button {
                    showImagePicker = true
                } label: {
                    ZStack(alignment: .leading) {
                        ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: viewModel.thread?.computedImageURL, userName: viewModel.thread?.computedTitle)
                            .scaledToFit()
                            .id(viewModel.thread?.id)
                            .font(.iransansBoldCaption2)
                            .foregroundColor(.white)
                            .frame(width: 128, height: 128)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(54)
                            .overlay(alignment: .center) {
                                /// Showing the image taht user has selected.
                                if let image = viewModel.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(54)
                                }
                            }
                        Circle()
                            .fill(.red)
                            .frame(width: 32, height: 32)
                            .offset(x: 90, y: 42)
                            .blendMode(.destinationOut)
                            .overlay {
                                Image(systemName: "camera")
                                    .font(.system(size: 11))
                                    .frame(width: 27, height: 27)
                                    .background(Color.hint)
                                    .cornerRadius(18)
                                    .foregroundColor(.white)
                                    .fontWeight(.heavy)
                                    .offset(x: 90, y: 42)

                            }
                    }
                    .compositingGroup()
                    .opacity(0.9)
                }
                Spacer()
            }
            .padding()
            .listRowBackground(Color.bgColor)
            .noSeparators()

            StickyHeaderSection(header: "", height: 2)
                .listRowBackground(Color.bgColor)
                .listRowInsets(.zero)
                .noSeparators()

            TextField("EditGroup.groupName", text: $viewModel.editTitle)
                .focused($focusState, equals: .name)
                .keyboardType(.default)
                .padding()
                .applyAppTextfieldStyle(topPlaceholder: "EditGroup.groupName", isFocused: focusState == .name) {
                    focusState = .name
                }
                .noSeparators()
                .listRowBackground(Color.bgColor)

            TextField("EditGroup.groupDescription", text: $viewModel.threadDescription)
                .focused($focusState, equals: .description)
                .keyboardType(.default)
                .padding()
                .applyAppTextfieldStyle(topPlaceholder: "EditGroup.groupDescription", minHeigh: 128, isFocused: focusState == .description) {
                    focusState = .description
                }
                .noSeparators()
                .listRowBackground(Color.bgColor)
        }
        .animation(.easeInOut, value: focusState)
        .padding(0)
        .listStyle(.plain)
        .background(Color.bgColor)
        .safeAreaInset(edge: .bottom) {
            EmptyView()
                .frame(height: 72)
        }
        .overlay(alignment: .bottom) {
            SubmitBottomButton(text: "General.edit", enableButton: Binding(get: {!viewModel.isLoading}, set: {_ in}), isLoading: $viewModel.isLoading) {
                viewModel.submitEditGroup()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                showImagePicker = false
                self.viewModel.image = image
                self.viewModel.assetResources = assestResources ?? []
            }
        }
    }
}

struct EditGroup_Previews: PreviewProvider {
    static var previews: some View {
        EditGroup()
            .environmentObject(DetailViewModel(thread: .init(id: 1)))
    }
}
