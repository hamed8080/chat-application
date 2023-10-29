//
//  SupportView.swift
//  Talk
//
//  Created by hamed on 10/14/23.
//

import SwiftUI

struct SupportView: View {
    @Environment(\.colorScheme) var scheme
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                Image("support_icon")
                    .resizable()
                    .scaledToFit()
                    .padding(32)
                    .frame(width: 120, height: 120)
                    .background(scheme == .dark ? Color.App.white.opacity(0.2) : Color.App.primary)
                    .cornerRadius(64)
                    .foregroundStyle(.white)
                Text("Support.aboutUsText")
                    .frame(maxWidth: 320)
                    .multilineTextAlignment(.center)
                let isIpad = UIDevice.current.userInterfaceIdiom  == .pad
                Link(destination: URL(string: "\(isIpad ? "facetime" : "tel"):021-91033000")!) {
                    HStack {
                        Text("021-91033000")
                        Image(systemName: "phone")
                    }
                }

                Link(destination: URL(string: "\(isIpad ? "facetime" : "tel"):0903-4565089")!) {
                    HStack {
                        Text("0903-4565089")
                        Image(systemName: "phone")
                    }
                }
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                Text(String(format: String(localized: "Support.version"), version))
                    .foregroundStyle(Color.App.hint)
            }
        }
        .font(.iransansBody)
    }
}

struct SupportView_Previews: PreviewProvider {
    static var previews: some View {
        SupportView()
    }
}
