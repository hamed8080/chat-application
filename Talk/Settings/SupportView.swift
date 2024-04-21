//
//  SupportView.swift
//  Talk
//
//  Created by hamed on 10/14/23.
//

import SwiftUI
import TalkViewModels

struct SupportView: View {
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image("talk_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(Color.App.accent)
                .padding(.bottom, 8)

            Text("Support.title")
                .fontWeight(.bold)
                .foregroundStyle(Color.App.textPrimary)

            Text("Support.aboutUsText")
                .multilineTextAlignment(.leading)
                .lineSpacing(5)
                .foregroundStyle(Color.App.textPrimary)
            let isIpad = UIDevice.current.userInterfaceIdiom  == .pad

            Rectangle()
                .fill(Color.clear)
                .frame(height: 96)
            Text("Support.callDetail")
                .foregroundStyle(Color.App.textPrimary)
            HStack(spacing: 8) {
                Link(destination: URL(string: "\(isIpad ? "facetime" : "tel"):021-91033000")!) {
                    Text("Support.number")
                }
                Spacer()
            }
            .foregroundStyle(Color.App.textSecondary)

            Spacer()

            Text(String(format: String(localized: "Support.version"), localVersionNumber))
                .foregroundStyle(Color.App.textSecondary)
        }
        .font(.iransansBody)
        .padding(EdgeInsets(top: 72, leading: 24, bottom: 30, trailing: 24))
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.App.bgPrimary)
        .normalToolbarView(title: "Settings.about", type: SupportNavigationValue.self)
    }

    private var localVersionNumber: String {
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let splited = version.split(separator: ".")
        let numbers = splited.compactMap({Int($0)})
        let localStr = numbers.compactMap{$0.localNumber()}
        return localStr.joined(separator: ".")
    }
}

struct SupportView_Previews: PreviewProvider {
    static var previews: some View {
        SupportView()
    }
}
