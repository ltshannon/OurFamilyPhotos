//
//  SettingsView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import FirebaseSignInWithApple

struct SettingsView: View {
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
            }
            .padding([.leading, .trailing], 20)
        }
    }
}
