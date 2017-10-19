//
//  NotificationManager.swift
//  AlpsSDK
//
//  Created by Wen on 13.10.17.
//  Copyright © 2017 Alps. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class NotificationManager : NSObject, UNUserNotificationCenterDelegate {
    var alpsManager : AlpsManager
    var deviceToken : Data?
    var deviceTokenString = ""
    var seenError = false
    
    init(alpsManager: AlpsManager){
        self.alpsManager = alpsManager
        super.init()
    }
    
    func initialize() {
        self.seenError = registerForPushNotifications()
    }
    
    private func registerForPushNotifications() -> Bool{
        // iOS 10 support
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in
                NSLog("***********************************************")
                NSLog("Permission granted: \(granted)")
                
                guard granted else {self.seenError = true
                    return }
                // If get notification settings is not .authorized, register for remote notification is not called
                self.getNotificationSettings()
                UNUserNotificationCenter.current().delegate = self
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
            // iOS 9 support
        else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            self.getNotificationSettings()
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 8 support
        else if #available(iOS 8, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            self.getNotificationSettings()
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 7 support
        else {  
            UIApplication.shared.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
            self.getNotificationSettings()
        }
        
        NSLog("Notification Manager is initialized.")
        return !UIApplication.shared.isRegisteredForRemoteNotifications
    }
    
    
    private func getNotificationSettings(){
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                NSLog("***********************************************")
                NSLog("Notification settings: \(settings)")
                guard settings.authorizationStatus == .authorized else { return }
            }
        } else {
            // Fallback on earlier versions
            NSLog("************PREVIOUS VERSION")
        }
    }
    
    // Called when AppDelegate func didRegisterForRemoteNotificationsWithDeviceToken
    //
    func registerDeviceToken(deviceToken: Data, deviceTokenString : String){
        NSLog("REGISTERED DEVICE TOKEN")
        self.deviceToken = deviceToken
        self.deviceTokenString = deviceTokenString
    }
    
    func handleRemoteNotification(userInfo: [AnyHashable : Any]){
        NSLog("--------- handle remote notification")
        NSLog(userInfo.description)
    }
    
    // MARK: UNUserNotificationCenter Delegate
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Called when app is open in background and click on notification
        NSLog("did Receive function : ")
        NSLog(response.notification.request.content.body)
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Called when app is in foreground
        // Assume that the request.content.body contains the match id.
        NSLog("will present function : ")
        NSLog(notification.request.content.body)
    }
}
