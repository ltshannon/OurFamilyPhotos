//
//  HomeView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import Photos

struct HomeView: View {
    @State private var firstTime = true
    
    var body: some View {
        TabView {
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
            SelectPhotoView()
                .tabItem {
                    Label("Upload", systemImage: "square.and.arrow.up")
                }
                .tag(3)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
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
                firstTime = false
            }
        }
    }
}
