//
//  ModelTests.swift
//  AlpsSDK
//
//  Created by Wen on 18.08.17.
//  Copyright © 2017 Alps. All rights reserved.
//

import XCTest
@testable import Alps
@testable import AlpsSDK

// Test the Alps class implementation

class ModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitLocation() {
        // 1. given
        let location = Location.init(latitude: 37.7858, longitude: -122.4064, altitude: 100, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        let json = ["latitude": 37.7858, "verticalAccuracy": 5.0, "horizontalAccuracy": 5.0, "longitude": -122.4064, "altitude": 100.0] as Any
        
        // 3. should equal
//        XCTAssertEqual(location.latitude, 37.7858, "Returned latitude is not equal to defined one.")
//        XCTAssertEqual(location.longitude, -122.4064, "Returned longitude is not equal to defined one.")
//        XCTAssertEqual(location.altitude, 100.0, "Returned altitude is not equal to defined one.")
//        XCTAssertEqual(location.horizontalAccuracy, 5.0, "Returned horizontalAccuracy is not equal to defined one.")
//        XCTAssertEqual(location.verticalAccuracy, 5.0, "Returned verticalAccuracy is not equal to defined one.")
        XCTAssertEqual(String(describing: location.encodeToJSON()), String(describing: json))
    }
    
    func testInitMobileDevice() {
        // 1. given
        let location = Location.init(latitude: 37.7858, longitude: -122.4064, altitude: 100, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        let mobileDevice = MobileDevice.init(name: "iPhone 7", platform: "iOS 10.2",deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb662", location: location)
        let json = ["deviceType": "MobileDevice",
                    "name": "iPhone 7",
                    "deviceToken": "870470ea-7a8e-11e6-b49b-5358f3beb662",
                    "location": ["latitude": 37.7858, "verticalAccuracy": 5.0, "horizontalAccuracy": 5.0, "longitude": -122.4064, "altitude": 100.0],
                    "platform": "iOS 10.2"] as Any
        
        // 3. should equal
        XCTAssertNil(mobileDevice.id)
//        XCTAssertEqual(mobileDevice.name, "iPhone 7")
//        XCTAssertEqual(mobileDevice.platform, "iOS 10.2")
//        XCTAssertEqual(mobileDevice.deviceToken, "870470ea-7a8e-11e6-b49b-5358f3beb662")
//        XCTAssertNotNil(mobileDevice.location)
        XCTAssertEqual(String(describing: mobileDevice.encodeToJSON()), String(describing: json))
    }
    
    func testInitPinDevice() {
        // 1. given
        let location = Location.init(latitude: 37.7858, longitude: -122.4064, altitude: 100, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        let pinDevice = PinDevice.init(name: "Alps pin device", location: location)
        let json = ["name": "Alps pin device",
                    "deviceType": "PinDevice",
                    "location": ["latitude": 37.7858, "verticalAccuracy": 5.0, "horizontalAccuracy": 5.0, "longitude": -122.4064, "altitude": 100.0]] as Any
        
        // 3. should equal
        XCTAssertNil(pinDevice.id)
//        XCTAssertEqual(pinDevice.name, "Alps pin device")
//        XCTAssertNotNil(pinDevice.location)
        XCTAssertEqual(String(describing: pinDevice.encodeToJSON()), String(describing: json))
        
    }
    
    func testInitBeaconDevice() {
        // 1. given
        let iBeaconDevice = IBeaconDevice.init(name: "beacon1 - rose", proximityUUID: "B9407F30-F5F8-466E-AFF9-25556B57FE6D", major: 21978, minor: 59907)
        let json = ["name": "beacon1 - rose",
                    "deviceType": "IBeaconDevice",
                    "proximityUUID": "B9407F30-F5F8-466E-AFF9-25556B57FE6D",
                    "major": 21978,
                    "minor": 59907] as Any
        
        // 3. should equal
        XCTAssertNil(iBeaconDevice.id)
//        XCTAssertEqual(iBeaconDevice.name, "beacon1 - rose")
//        XCTAssertEqual(iBeaconDevice.proximityUUID, "B9407F30-F5F8-466E-AFF9-25556B57FE6D")
//        XCTAssertEqual(iBeaconDevice.major, 21978)
//        XCTAssertEqual(iBeaconDevice.minor, 59907)
        XCTAssertEqual(String(describing: iBeaconDevice.encodeToJSON()), String(describing: json))
    }
    
    func testInitPublication() {
        // 1. given
        let properties : [String:String] = ["role": "developer"]
        let publication = Publication.init(deviceId: "1234567890", topic: "alps-test", range: 100.0, duration: 0.0, properties: properties)
        let json = ["deviceId": "1234567890",
                    "topic": "alps-test",
                    "range": 100.0,
                    "duration": 0.0,
                    "properties": ["role": "developer"]] as Any
        // 3. should equal
        // Test each fields
        XCTAssertNil(publication.id)
//        XCTAssertEqual(publication.deviceId, "1234567890")
//        XCTAssertEqual(publication.topic, "alps-test")
//        XCTAssertEqual(publication.range, 100.0)
//        XCTAssertEqual(publication.duration, 0.0)
//        XCTAssertNotNil(publication.properties)
        XCTAssertEqual(String(describing: publication.encodeToJSON()), String(describing: json))
        print(publication.encodeToJSON())
        print(json)
        
        
    }
    
    func testInitSubscription() {
        // 1. given
        let subscription = Subscription.init(deviceId: "1234567890", topic: "alps-test", range: 100.0, duration: 0.0, selector: "role = 'developer'")
        let json = ["deviceId": "1234567890",
                    "topic": "alps-test",
                    "selector": "role = 'developer'",
                    "range": 100.0,
                    "duration": 0.0] as Any
        
        // 3. should equal
        // Test each fields
        XCTAssertNil(subscription.id)
//        XCTAssertEqual(subscription.deviceId, "1234567890")
//        XCTAssertEqual(subscription.topic, "alps-test")
//        XCTAssertEqual(subscription.range, 100.0)
//        XCTAssertEqual(subscription.duration, 0.0)
//        XCTAssertEqual(subscription.selector, "role = 'developer'")
        XCTAssertEqual(String(describing: subscription.encodeToJSON()), String(describing: json))
           }
}
