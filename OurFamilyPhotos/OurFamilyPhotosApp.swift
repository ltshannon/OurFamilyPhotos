//
//  OurFamilyPhotosApp.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import FirebaseSignInWithApple

@main
struct OurFamilyPhotosApp: App {
    @StateObject var appNavigationState = AppNavigationState()
    @StateObject var firebaseService = FirebaseService.shared
    @StateObject var settingsService = SettingsService.shared
    @StateObject var userAuth = Authentication.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appNavigationState)
                .environmentObject(firebaseService)
                .environmentObject(settingsService)
                .environmentObject(userAuth)
                .configureFirebaseSignInWithAppleWith(firestoreUserCollectionPath: Path.Firestore.profiles)
        }
    }
}
