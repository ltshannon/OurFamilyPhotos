//
//  HomeView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import Photos

struct HomeView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var userAuth: Authentication
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var firstTime = true
    @State private var showingFullScreenCover = false
    
    var body: some View {
        TabView(selection: $userAuth.tabSelection) {
            DisplayPhotoView()
                .tabItem {
                    Label("Photos", systemImage: "photo")
                }
                .tag(1)
            PublicFoldersView()
                .tabItem {
                    Label("Public Photos", systemImage: "folder")
                }
                .tag(2)
            AccessRequestsView()
                .tabItem {
                    Label("Access Requests", systemImage: "lock.shield")
                }
                .tag(3)
            SelectPhotoView()
                .tabItem {
                    Label("Upload", systemImage: "square.and.arrow.up")
                }
                .tag(4)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
        }
        .onAppear {
            if firstTime {
                let status = PHPhotoLibrary.authorizationStatus()

                switch status {
                case .notDetermined:
                  PHPhotoLibrary.requestAuthorization { newStatus in
                    if newStatus == .authorized {
                      debugPrint("Access granted.")
                    } else {
                        debugPrint("Access denied.")
                    }
                  }
                case .restricted, .denied:
                    debugPrint("Access denied or restricted.")
                case .authorized:
                    debugPrint("Access already granted.")
                case .limited:
                    debugPrint("Access limited.")
                @unknown default:
                    debugPrint("Unknown authorization status.")
                }
                Task {
                    await firebaseService.getUserName()
                    if firebaseService.userName.isEmpty {
                        showingFullScreenCover = true
                    }
                }
                firstTime = false
            }
        }
        .fullScreenCover(isPresented: $showingFullScreenCover) {
            GetUserNameView()
        }
        .onReceive(userAuth.$fcmToken) { token in
            if token.isNotEmpty {
                Task {
                    await firebaseService.updateAddFCMToUser(token: userAuth.fcmToken)
                }
            }
        }
//        .onReceive(userAuth.$silent) { value in
//            if value == true {
//                showingFullScreenCover = true
//            }
//        }
    }
}
