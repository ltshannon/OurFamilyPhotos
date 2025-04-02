//
//  AppDelegate.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        debugPrint("Firebase configured")
        return true
    }
    
    func application(_ application: UIApplication,
                        configurationForConnecting connectingSceneSession: UISceneSession,
                        options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self // Here we specify the scene delegate we just created
        return sceneConfiguration
    }
}
