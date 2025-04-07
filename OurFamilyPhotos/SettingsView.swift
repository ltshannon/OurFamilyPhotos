//
//  SettingsView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import FirebaseSignInWithApple

struct SettingsView: View {
    @State var version = ""
    
    var body: some View {
        ZStack {
            Color("Background-grey").edgesIgnoringSafeArea(.all)
            VStack {
                FirebaseSignOutWithAppleButton {
                    FirebaseSignInWithAppleLabel(.signOut)
                }
                FirebaseDeleteAccountWithAppleButton {
                    FirebaseSignInWithAppleLabel(.deleteAccount)
                }
                Spacer()
                Text(version)
            }
            .padding([.leading, .trailing], 20)
        }
        .onAppear {
            let dict = Bundle.main.infoDictionary!
            let versionString = dict["CFBundleShortVersionString"] as! String
            let build = dict["CFBundleVersion"] as! String
            version = "Version: \(versionString) Build: \(build)"
        }
    }
}
