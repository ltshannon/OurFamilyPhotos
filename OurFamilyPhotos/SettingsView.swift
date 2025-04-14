//
//  SettingsView.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import FirebaseSignInWithApple

struct SettingsView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State var version = ""
    @State private var showProfileView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background-grey").edgesIgnoringSafeArea(.all)
                VStack {
                    FirebaseSignOutWithAppleButton {
                        FirebaseSignInWithAppleLabel(.signOut)
                    }
                    FirebaseDeleteAccountWithAppleButton {
                        FirebaseSignInWithAppleLabel(.deleteAccount)
                    }
                    Button {
                        showProfileView = true
                    } label: {
                        Label("Edit Profile", systemImage: "applepencil")
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44.0, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .foregroundColor(.black)
                    .background(.white)
                    .cornerRadius(9)
                    .navigationDestination(isPresented: $showProfileView) {
                        ProfileView()
                    }
                    //                Button {
                    //                    firebaseService.callFirebaseCallableFunction(fcm: "fgfUVv2P1k8tl5aFWQ9ci7:APA91bG2F5W-OzB78EX3_UaSZzb2yKCJeY2bKWAUyTDlgHa8gyd0iQxBEzQlIghnnHtpw0VNQmnPgRn1bgGefWxJrbw8bShEvbO8CgEB7imq1AEBAam231M", title: "Tes", body: "This is a test", silent: true)
                    //                } label: {
                    //                    Text("Test Notification")
                    //                }
                    Spacer()
                    Text(version)
                }
                .padding([.leading, .trailing], 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            let dict = Bundle.main.infoDictionary!
            let versionString = dict["CFBundleShortVersionString"] as! String
            let build = dict["CFBundleVersion"] as! String
            version = "Version: \(versionString) Build: \(build)"
        }
    }
}
