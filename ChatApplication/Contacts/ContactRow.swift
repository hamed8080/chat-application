//
//  ContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct ContactRow: View {
    @Binding
    public var isInSelectionMode: Bool
    @EnvironmentObject
    var viewModel: ContactViewModel
    @State
    public var showActionViews: Bool = false
    var contact: Contact { viewModel.contact }
    var contactImageURL: String? { contact.image ?? contact.linkedUser?.image }
    @State
    var navigateToAddOrEditContact = false
    @State
    var imageLoader: ImageLoader

    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 0) {
                        Image(systemName: viewModel.isSelected ? "checkmark.circle" : "circle")
                            .font(.title)
                            .frame(width: 22, height: 22, alignment: .center)
                            .foregroundColor(Color.blue)
                            .padding(24)
                            .offset(x: isInSelectionMode ? 0 : -64 )
                            .frame(width: isInSelectionMode ? 48 : 0 )
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            .onTapGesture {
                                viewModel.toggleSelectedContact()
                            }

                    let token = EnvironmentValues().isPreview ? "FAKE_TOKEN" : TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken
                    Avatar(
                        imageLoader: imageLoader,
                        url: contactImageURL,
                        userName: contact.firstName?.uppercased(),
                        token: token
                    )
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                            .padding(.leading, 16)
                            .lineLimit(1)
                            .font(.headline)
                        if let notSeenDuration = ContactRow.getDate(notSeenDuration: contact.notSeenDuration) {
                            Text(notSeenDuration)
                                .padding(.leading, 16)
                                .font(.headline.weight(.medium))
                                .foregroundColor(Color.gray)
                        }
                    }
                    Spacer()
                    if contact.blocked == true {
                        Text("Blocked")
                            .font(.caption.weight(.medium))
                            .padding(4)
                            .foregroundColor(Color.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.red)
                            )
                    }
                }
                if showActionViews {
                    actionsViews
                } else {
                    EmptyView()
                }
            }
            .modifier(AnimatingCellHeight(height: self.showActionViews ? 148 : 64))
            .padding(SwiftUI.EdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8))
            .background(Color.primary.opacity(0.08))
            .cornerRadius(16)
        }
        .animation(.easeInOut, value: showActionViews)
        .animation(.easeInOut, value: viewModel.contact.blocked)
        .animation(.easeInOut, value: navigateToAddOrEditContact)
        .animation(.easeInOut, value: viewModel.contact)
        .autoNavigateToThread()
        .onTapGesture {
                showActionViews.toggle()
        }
        .sheet(isPresented: $navigateToAddOrEditContact) {
            AddOrEditContactView(editContact: viewModel.contact).environmentObject(viewModel)
        }
    }

    @ViewBuilder
    var actionsViews: some View {
        Divider()
        HStack(spacing: 48) {
            ActionButton(iconSfSymbolName: "message") {
                viewModel.contactsVM.createThread(invitees: [Invitee(id: "\(contact.id ?? 0)", idType: .contactId)])
            }

            ActionButton(iconSfSymbolName: "hand.raised.slash", iconColor: contact.blocked == true ? .red : .blue) {
                viewModel.blockOrUnBlock(contact)
            }

            ActionButton(iconSfSymbolName: "pencil") {
                navigateToAddOrEditContact.toggle()
            }
        }
    }

    static func getDate(notSeenDuration: Int?) -> String? {
        if let notSeenDuration = notSeenDuration {
            let milisecondIntervalDate = Date().millisecondsSince1970 - Int64(notSeenDuration)
            return Date(milliseconds: milisecondIntervalDate).timeAgoSinceDate()
        } else {
            return nil
        }
    }
}

struct ActionButton: View {
    var iconSfSymbolName: String
    var height: CGFloat = 22
    var iconColor: Color = .blue
    var taped: (() -> Void)?

    var body: some View {
        Button(action: {
            taped?()
        }, label: {
            Image(systemName: iconSfSymbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: height)
                .foregroundColor(iconColor)
        })
        .buttonStyle(BorderlessButtonStyle()) // don't remove this line click happen in all veiws
        .padding(16)
    }
}

struct ContactRow_Previews: PreviewProvider {
    @State static var isInSelectionMode = false

    static var previews: some View {
        Group {
            ContactRow(isInSelectionMode: $isInSelectionMode, imageLoader: ImageLoader(url: ""))
                .environmentObject(ContactViewModel(contact: MockData.contact, contactsVM: ContactsViewModel()))
                .preferredColorScheme(.dark)
        }
    }
}
