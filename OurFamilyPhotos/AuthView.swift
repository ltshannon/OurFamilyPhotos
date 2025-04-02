//
//  AuthView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import FirebaseSignInWithApple

struct AuthView: View {
    @Environment(\.firebaseSignInWithApple) private var firebaseSignInWithApple
    
    var body: some View {
        ZStack {
            Color("Background-grey").edgesIgnoringSafeArea(.all)
            VStack {
                FirebaseSignInWithAppleButton {
                    FirebaseSignInWithAppleLabel(.signIn)
                }
                .padding([.leading, .trailing], 20)
            }
        }
    }
}
