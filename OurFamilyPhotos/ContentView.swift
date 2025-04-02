//
//  ContentView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.firebaseSignInWithApple) var firebaseSignInWithApple
    
    var body: some View {
        Group {
            switch firebaseSignInWithApple.state {
            case .loading:
                ProgressView()
            case .authenticating:
                ProgressView()
            case .notAuthenticated:
                AuthView()
            case .authenticated:
                HomeView()
            }
        }
        .onChange(of: firebaseSignInWithApple.state) { oldValue, newValue in
            debugPrint("old: \(oldValue), new: \(newValue)")
        }
    }
}
#Preview {
    ContentView()
}
