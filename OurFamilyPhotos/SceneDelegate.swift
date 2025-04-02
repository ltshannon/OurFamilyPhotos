//
//  SceneDelegate.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/2/25.
//

import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
 
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
 
        if session.role == .windowExternalDisplayNonInteractive {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: ExternalDisplayView()) // Here we specify the view we want to display on the external screen
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
