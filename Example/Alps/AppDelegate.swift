//
//  AppDelegate.swift
//  Alps
//
//  Created by rk on 09/27/2016.
//  Copyright (c) 2016 rk. All rights reserved.
//

import UIKit
import Alps
import AlpsSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // Alps API key (please don't change for now)
    let alps = AlpsManager(apiKey: "ea0df90a-db0a-11e5-bd35-3bd106df139b")
    let userName = "Alps Example User"
    let deviceName = "Example User's iPhone 8"
    var device: Device?
    var window: UIWindow?

    func createDevice(completion: @escaping () -> Void) {
        alps.createUser(userName) {
            (_ user) in
            if let u = user {
                print("Created user: id = \(u.userId), name = \(u.name)")

                self.alps.createDevice(name: self.deviceName, platform: "iOS 10.2",
                                    deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb662",
                                    latitude: 37.7858, longitude: -122.4064, altitude: 0.0,
                                    horizontalAccuracy: 5.0, verticalAccuracy: 5.0) {
                    (_ device) in
                    if let d = device {
                        print("Created device: id = \(d.deviceId), name = \(d.name)")
                        self.device = d
                        completion()
                    }
                }
            }
        }
    }

    func createPublication() {
        if device != nil {
            // XXX: the property syntax is tricky at the moment: mood is a variable and 'happy' is a string value
            let properties = ["mood": "'happy'"]

            self.alps.createPublication(topic: "alps-ios-test",
                                          range: 100.0, duration: 60,
                                          properties: properties) {
                (_ publication) in
                if let p = publication {
                    print("Created publication: id = \(p.publicationId), topic = \(p.topic), properties = \(p.properties)")
                }
            }
        }
    }

    func createSubscription() {
        if device != nil {
            let selector = "mood = happy"

            self.alps.createSubscription(topic: "alps-ios-test",
                                           selector: selector, range: 100.0, duration: 60) {
                (_ subscription) in
                if let s = subscription {
                    print("Created subscription: id = \(s.subscriptionId), topic = \(s.topic), selector = \(s.selector)")
                }
            }
        }
    }

    func continouslyUpdatingLocation() {
        if device != nil {
            self.alps.startUpdatingLocation()
        }
    }

    func monitorMatches() {
        alps.startMonitoringMatches()
    }

    func monitorMatchesWithCompletion(completion: @escaping (_ match: Match) -> Void) {
        alps.onMatch(completion: completion)
        alps.startMonitoringMatches()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Make some Alps calls
        createDevice() {
            self.createPublication()
            self.createSubscription()
            self.continouslyUpdatingLocation()
            // without passing a closure the match monitor will just log the match to the console
            // self.monitorMatches()
            // Pass a closure to handle the match accordingly (it will repeatedly call for all matches for now)
            self.monitorMatchesWithCompletion { (_ match) in NSLog("match completion called with \(match)") }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}
