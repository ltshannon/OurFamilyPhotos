//
//  Authentication.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/4/25.
//

import Foundation
import SwiftUI
import UserNotifications
import AuthenticationServices
import FirebaseAuth

@MainActor
class Authentication: ObservableObject {
    static let shared = Authentication()
    @Published var user: User?
    @Published var fcmToken: String = ""
    private var handler: AuthStateDidChangeListenerHandle? = nil
    
    init() {
        
        handler = Auth.auth().addStateDidChangeListener { auth, user in
            debugPrint("🛎️", "Authentication Firebase auth state changed, logged in: \(auth.userIsLoggedIn)")
            
            self.user = user
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("FCMToken"), object: nil, queue: nil) { notification in
            let newToken = notification.userInfo?["token"] as? String ?? ""
            Task {
                await MainActor.run {
                    self.fcmToken = newToken
                }
            }
        }
    }
    
}

extension Auth {
    var userIsLoggedIn: Bool {
        currentUser != nil
    }
}
