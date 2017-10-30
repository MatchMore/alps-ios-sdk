//
//  AlpsManagerTests.swift
//  AlpsSDKTests
//
//  Created by Maciej Burda on 27/10/2017.
//  Copyright © 2017 Alps. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import Alps
@testable import AlpsSDK

final class AlpsManagerTests: QuickSpec {
    
    let kWaitTimeInterval = 10.0
    
    override func spec() {
        let alpsManager = AlpsManager(apiKey: "c9b9601d-55b9-4057-8331-f1e2c72d308d",
                                      baseUrl: "http://localhost:9000/v4")
        
        let properties = ["test": "true"]
        
        context("Alps Manager") {
            fit ("create main device") {
                alpsManager.createMainDevice()
                expect(alpsManager.mobileDevices.main).toEventuallyNot(beNil())
            }
            
            fit ("create a publication") {
                let publication = Publication(topic: "Test Topic", range: 20, duration: 100, properties: properties)
                alpsManager.createPublication(publication: publication)
                expect(alpsManager.publications.items).toEventuallyNot(beEmpty())
            }
            
            fit ("create a subscription") {
                let subscription = Subscription(topic: "Test Topic", range: 20, duration: 100, selector: "test = 'true'")
                alpsManager.createSubscription(subscription: subscription)
                expect(alpsManager.subscriptions.items).toEventuallyNot(beEmpty())
            }
            
            fit ("get a match") {
                guard let mainDevice = alpsManager.mobileDevices.main else { return }
                alpsManager.matchMonitor.startMonitoringFor(device: mainDevice)
                expect(alpsManager.matchMonitor.deliveredMatches).toEventuallyNot(beEmpty())
            }
            
        }
        
    }
}
