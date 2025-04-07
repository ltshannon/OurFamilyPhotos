//
//  AppDelegate.swift
//  OurFamilyPhotos
//
//  Created by Larry Shannon on 4/1/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
    
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { granted, error in
                    debugPrint("😎", "Notification permission granted: \(granted)")
                })
            Messaging.messaging().delegate = self
        }
        
        application.registerForRemoteNotifications()
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
    
    @MainActor
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
    
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        print(userInfo)
        
        return UIBackgroundFetchResult.newData

    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       debugPrint("didRegisterForRemoteNotificationsWithDeviceToken")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        debugPrint("didFailToRegisterForRemoteNotificationsWithError")
    }
    
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")
        
        let tokenDict = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: tokenDict)
        debugPrint("messaging: \(tokenDict)")
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        debugPrint("userNotificationCenter: willPresent")
        let userinfo = notification.request.content.userInfo
        
        if let messageID = userinfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print("userInfo: \(userinfo)")
        completionHandler([[.banner, .badge, .sound]])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userinfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: Notification.Name("didReceiveRemoteNotification"), object: nil, userInfo: userinfo)
        debugPrint("userNotificationCenter: didReceive")
        completionHandler()
    }
    
}
