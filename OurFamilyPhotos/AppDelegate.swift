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
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                debugPrint("😎", "Notification permission granted: \(granted)")
            })

        application.registerForRemoteNotifications()
        
        FirebaseApp.configure()
        debugPrint("🤥", "Firebase configured")
        
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication,
                        configurationForConnecting connectingSceneSession: UISceneSession,
                        options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        debugPrint("🤥", "configurationForConnecting")
        sceneConfiguration.delegateClass = SceneDelegate.self // Here we specify the scene delegate we just created
        return sceneConfiguration
    }
    
    @MainActor
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
    
        debugPrint("🤥", "didReceiveRemoteNotification")
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        debugPrint("🤥", userInfo)
        
        if let title = userInfo["title"] as? String, let body = userInfo["body"] as? String {
            let dataDict: [String: String] = ["key1": title, "key2" : body]
            NotificationCenter.default.post(
                name: Notification.Name("silent"),
                object: nil,
                userInfo: dataDict
            )
        }
        
        return UIBackgroundFetchResult.newData

    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        debugPrint("🤥", "didRegisterForRemoteNotificationsWithDeviceToken")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        debugPrint("🤥", "didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
    
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        debugPrint("🤥", "Firebase registration token: \(String(describing: fcmToken))")
        
        Messaging.messaging().token { token, error in
          if let error = error {
              debugPrint(String.fatal, "Error fetching FCM registration token: \(error)")
          } else if let token = token {
              debugPrint("🤥", String.success, "FCM registration token: \(token)")
          }
        }
        
        let tokenDict = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: tokenDict)
//        debugPrint("🤥", "messaging: \(tokenDict)")
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        debugPrint("🤥", "userNotificationCenter: willPresent")
        let userinfo = notification.request.content.userInfo
        
        if let messageID = userinfo[gcmMessageIDKey] {
            debugPrint("🤥", "Message ID: \(messageID)")
        }
        
        debugPrint("🤥","userInfo: \(userinfo)")
        completionHandler([[.banner, .badge, .sound]])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        
        let userinfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: Notification.Name("didReceiveRemoteNotification"), object: nil, userInfo: userinfo)
        debugPrint("🤥", "userNotificationCenter: didReceive")
    }
    
}
