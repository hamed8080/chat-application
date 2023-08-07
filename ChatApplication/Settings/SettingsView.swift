//
//  SettingsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            UserProfileView()
            Group {
                SettingSettingSection()
                SettingCallHistorySection()
                SettingSavedMessagesSection()
                SettingLogSection()
                SettingAssistantSection()
                SettingCallSection()
            }
            .font(.iransansSubheadline)
            .padding(8)
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    // TODO: - Must be added after server fix the problem
                } label: {
                    Label {
                        Text("Edit")
                    } icon: {
                        Image(systemName: "square.and.pencil")
                            .font(.iransansBody)
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                ConnectionStatusToolbar()
            }
        }
        .navigationTitle(Text("Settings"))
    }
}

struct SettingSettingSection: View {
    var body: some View {
        Section {
            NavigationLink {} label: {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                    Text("Setting")
                }
            }
        }
    }
}

struct SettingCallHistorySection: View {
    var body: some View {
        Section {
            NavigationLink {} label: {
                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.green)
                    Text("Calls")
                }
            }
        }
    }
}

struct SettingSavedMessagesSection: View {
    var body: some View {
        NavigationLink {} label: {
            HStack {
                Image(systemName: "bookmark")
                    .foregroundColor(.purple)
                Text("Saved Messages")
            }
        }
    }
}

struct SettingLogSection: View {
    var body: some View {
        NavigationLink {
            LogView()
        } label: {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.purple)
                Text("Logs")
            }
        }
    }
}

struct SettingAssistantSection: View {
    var body: some View {
        NavigationLink {
            AssistantView()
        } label: {
            HStack {
                Image(systemName: "person.badge.shield.checkmark")
                    .foregroundColor(.purple)
                Text("Assistants")
            }
        }
    }
}

struct UserProfileView: View {
    @EnvironmentObject var container: ObjectsContainer
    var user: User? { container.userConfigsVM.currentUserConfig?.user }

    var body: some View {
        Section {
            HStack {
                Spacer()
                Circle()
                    .fill(Color.gray.opacity(0.08))
                    .frame(width: 128, height: 128)
                    .shadow(color: .black, radius: 20, x: 0, y: 0)
                    .overlay(
                        ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: user?.image, userName: user?.username ?? user?.name, size: .LARG)
                            .id("\(user?.image ?? "")\(user?.id ?? 0)")
                            .font(.system(size: 16).weight(.heavy))
                            .foregroundColor(.white)
                            .frame(width: 128, height: 128)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(64)
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onEnded { value in
                                if value.translation.height != 0 {
                                    // TODO: Switch user with swipe action
                                    //                                            viewModel.switchUser(isNext: value.translation.height < 0)
                                }
                            }
                    )
                Spacer()
            }
            .noSeparators()

            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Text(user?.name ?? "")
                        .font(.iransansBoldTitle)

                    Text(user?.cellphoneNumber ?? "")
                        .font(.iransansSubheadline)
                }
                Spacer()
            }
            .padding([.top, .bottom], 25)
            .noSeparators()
        }
        .padding()
    }
}

struct SettingCallSection: View {
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        Section(header: Text("Manage Calls").font(.headline)) {
            Button {
                ChatManager.activeInstance?.user.logOut()
                TokenManager.shared.clearToken()
                UserConfigManagerVM.instance.logout(delegate: ChatDelegateImplementation.sharedInstance)
                container.reset()
            } label: {
                HStack {
                    Image(systemName: "arrow.backward.circle")
                        .foregroundColor(.red)
                        .font(.body.weight(.bold))
                    Text("Logout")
                        .fontWeight(.bold)
                        .foregroundColor(Color.red)
                    Spacer()
                }
            }
            TokenExpireView()
        }
    }
}

struct TokenExpireView: View {
    @EnvironmentObject var viewModel: TokenManager

    var body: some View {
        #if DEBUG
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(Color.yellow)
                    .frame(width: 24, height: 24)
                let secondToExpire = viewModel.secondToExpire.formatted(.number.precision(.fractionLength(0)))
                Text("Token expire in: \(secondToExpire)")
                    .foregroundColor(Color.gray)
                Spacer()
            }
            .onAppear {
                viewModel.startTokenTimer()
            }
        #endif
    }
}

struct SettingsMenu_Previews: PreviewProvider {
    @State static var dark: Bool = false
    @State static var show: Bool = false
    @State static var showBlackView: Bool = false
    @StateObject static var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)
    static var vm = SettingViewModel()

    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(vm)
                .environmentObject(container)
                .environmentObject(TokenManager.shared)
                .environmentObject(AppState.shared)
                .onAppear {
                    let user = User(
                        cellphoneNumber: "+98 936 916 1601",
                        email: "h.hosseini.co@gmail.com",
                        image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png",
                        name: "Hamed Hosseini",
                        username: "hamed8080"
                    )
                    container.userConfigsVM.onUser(user)
                }
        }
    }
}
