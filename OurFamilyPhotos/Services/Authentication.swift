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
    @Published var silent: Bool = false
    @Published var key1: String = ""
    @Published var key2: String = ""
    @Published var tabSelection = 1
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
        
        NotificationCenter.default.addObserver(forName: Notification.Name("silent"), object: nil, queue: nil) { notification in
            let key1 = notification.userInfo?["key1"] as? String ?? ""
            let key2 = notification.userInfo?["key2"] as? String ?? ""
            debugPrint("key1 \(key1)")
            debugPrint("key2 \(key2)")
            DispatchQueue.main.async {
                self.key1 = key1
                self.key2 = key2
                self.silent = true
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("didReceiveRemoteNotification"), object: nil, queue: nil) { notification in
            Task {
                await MainActor.run {
                    self.tabSelection = 3
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
