//
//  AlpsTests.swift
//  AlpsTests
//
//  Created by Rafal Kowalski on 22.09.16.
//  Copyright © 2016 Alps. All rights reserved.
//

import Foundation
import XCTest
import Alps
@testable import AlpsSDK


class AlpsSDKTests: XCTestCase {
    let apiKey = "ea0df90a-db0a-11e5-bd35-3bd106df139b"
    // var alps: AlpsSDK

    override func setUp() {
        super.setUp()
        // alps = AlpsManager(apiKey: apiKey)
    }

    override func tearDown() {
        super.tearDown()
    }

    func test1CreateUser() {
        let alps = AlpsManager(apiKey: apiKey)
        let expectation = self.expectation(description: "CreateUser")

        alps.createUser("Swift User 1") {
            (_ user) in
            XCTAssertNotNil(user, "Whoops, no user")
            XCTAssertNotNil(user?.id, "test1CreateUser(): id is nil.")
            XCTAssertNotNil(user?.createdAt, "test1CreateUser(): createdAt is nil.")
            print("")
            if let name = user?.name {
                XCTAssertEqual(name, "Swift User 1", "test1CreateUser(): Returned name is not equal to defined one.")
            } else {
                XCTFail("test1CreateUser(): name is nil.")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }


    func test2CreateMobileDevice() {
        let alps = AlpsManager(apiKey: apiKey)
        let deviceExpectation = expectation(description: "test2CreateMobileDevice")


        alps.createUser("Swift User 2") {
            (_ user) in
            if let _ = user {
                alps.createMobileDevice(name: "iPhone 7", platform: "iOS 10.2",
                                    deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb662",
                                    latitude: 37.7858, longitude: -122.4064, altitude: 100,
                                    horizontalAccuracy: 5.0, verticalAccuracy: 5.0) {
                    (_ device) in
                    XCTAssertNotNil(device, "Whoops, no device")
                    // Test each fields
                    if let deviceType = device?.deviceType?.rawValue {
                        XCTAssertEqual(deviceType, "MobileDevice", "test2CreateMobileDevice(): deviceType is not equal to right type.")
                    } else {
                        XCTFail("test2CreateMobileDevice(): deviceType is nil.")
                    }
                    XCTAssertNotNil(device?.id, "test2CreateMobileDevice(): id is nil.")
                    if let name = device?.name {
                        XCTAssertEqual(name, "iPhone 7", "test2CreateMobileDevice(): Returned name is not equal to defined one.")
                    } else {
                        XCTFail("test2CreateMobileDevice(): name is nil.")
                    }
                    if let platform = device?.platform {
                        XCTAssertEqual(platform, "iOS 10.2", "test2CreateMobileDevice(): Returned platform is not equal to defined one.")
                    } else {
                        XCTFail("test2CreateMobileDevice(): platform is nil.")
                    }
                    if let deviceToken = device?.deviceToken {
                        XCTAssertEqual(deviceToken, "870470ea-7a8e-11e6-b49b-5358f3beb662", "test2CreateMobileDevice(): Returned deviceToken is not equal to defined one.")
                    } else {
                        XCTFail("test2CreateMobileDevice(): deviceToken is nil.")
                    }
                    if let location = device?.location {
                        XCTAssertEqual(location.latitude, 37.7858, "test2CreateMobileDevice(): Returned latitude is not equal to defined one.")
                        XCTAssertEqual(location.longitude, -122.4064, "test2CreateMobileDevice(): Returned longitude is not equal to defined one.")
                        XCTAssertEqual(location.altitude, 100.0, "test2CreateMobileDevice(): Returned altitude is not equal to defined one.")
//                        XCTAssertEqual(location.horizontalAccuracy, 5.0, "test2CreateMobileDevice(): Returned horizontalAccuracy is not equal to defined one.")
//                        XCTAssertEqual(location.verticalAccuracy, 5.0, "test2CreateMobileDevice(): Returned verticalAccuracy is not equal to defined one.")
                    } else {
                        XCTFail("test2CreateMobileDevice(): location is nil.")
                    }
                    deviceExpectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func test3CreatePublication() {
        let alps = AlpsManager(apiKey: apiKey)
        let publicationExpectation = expectation(description: "test3CreatePublication")

        alps.createUser("Swift User 3") {
            (_ user) in
            if user != nil {
                alps.createMobileDevice(name: "iPhone 7", platform: "iOS 10.2",
                                    deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb663",
                                    latitude: 37.7858, longitude: -122.4064, altitude: 100,
                                    horizontalAccuracy: 5.0, verticalAccuracy: 5.0) {
                    (_ device) in
                    if let device = device {
                        // FIXME: provide serialization to json string
                        let properties = ["mood": "'happy'"]
                        // let propertiesString = "{\"mood\": \"happy\"}"

                        alps.createPublication(topic: "alps-ios-test", range: 100.0,
                                                 duration: 0, properties: properties) {
                            (_ publication) in
                            XCTAssertNotNil(publication)
                            // Test each fields
                            XCTAssertNotNil(publication?.id, "test3CreatePublication(): id is nil.")
                            if let deviceId = publication?.deviceId {
                                XCTAssertEqual(deviceId, device.id, "test3CreatePublication(): deviceId is not equal to defined one.")
                            } else {
                                XCTFail("test3CreatePublication(): deviceId is nil.")
                            }
                            if let topic = publication?.topic {
                                XCTAssertEqual(topic, "alps-ios-test", "test3CreatePublication(): topic is not equal to defined one.")
                            } else {
                                XCTFail("test3CreatePublication(): topic is nil.")
                            }
                            if let range = publication?.range {
                                XCTAssertEqual(range, 100.0, "test3CreatePublication(): range is not equal to defined one.")
                            } else {
                                XCTFail("test3CreatePublication(): range is nil.")
                            }
                            if let duration = publication?.duration {
                                XCTAssertEqual(duration, 0.0, "test3CreatePublication(): duration is not equal to defined one.")
                            } else {
                                XCTFail("test3CreatePublication(): duration is nil.")
                            }
                            if let testedProperties = publication?.properties {
                                XCTAssertEqual(testedProperties, properties, "test3CreatePublication(): properties is not equal to defined one.")
                            } else {
                                XCTFail("test3CreatePublication(): properties is nil.")
                            }
                            publicationExpectation.fulfill()
                        }
                    }
                }
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func test4CreateSubscription() {
        let alps = AlpsManager(apiKey: apiKey)
        let subscriptionExpectation = expectation(description: "test4CreateSubscription")

        alps.createUser("Swift User 4") {
            (_ user) in
            if user != nil {
                alps.createMobileDevice(name: "iPhone 7", platform: "iOS 10.2",
                                    deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb664",
                                    latitude: 37.7858, longitude: -122.4064, altitude: 100,
                                    horizontalAccuracy: 5.0, verticalAccuracy: 5.0) {
                    (_ device) in
                    if let device = device {
                        alps.createSubscription(topic: "alps-ios-test",
                                                  selector: "mood = 'happy'",
                                                  range: 100.0,
                                                  duration: 0) {
                            (_ subscription) in
                            XCTAssertNotNil(subscription)
                            
                            // Test each fields
                            XCTAssertNotNil(subscription?.id, "test4CreateSubscription(): id is nil.")
                            if let deviceId = subscription?.deviceId {
                                XCTAssertEqual(deviceId, device.id, "test4CreateSubscription(): deviceId is not equal to defined one.")
                            } else {
                                XCTFail("test4CreateSubscription(): deviceId is nil.")
                            }
                            if let topic = subscription?.topic {
                                XCTAssertEqual(topic, "alps-ios-test", "test4CreateSubscription(): topic is not equal to defined one.")
                            } else {
                                XCTFail("test4CreateSubscription(): topic is nil.")
                            }
                            if let range = subscription?.range {
                                XCTAssertEqual(range, 100.0, "test4CreateSubscription(): range is not equal to defined one.")
                            } else {
                                XCTFail("test4CreateSubscription(): range is nil.")
                            }
                            if let duration = subscription?.duration {
                                XCTAssertEqual(duration, 0.0, "test4CreateSubscription(): duration is not equal to defined one.")
                            } else {
                                XCTFail("test4CreateSubscription(): duration is nil.")
                            }
                            if let selector = subscription?.selector {
                                XCTAssertEqual(selector, "mood = 'happy'", "test4CreateSubscription(): selector is not equal to defined one.")
                            } else {
                                XCTFail("test4CreateSubscription(): properties is nil.")
                            }
                            subscriptionExpectation.fulfill()
                        }
                    }
                }
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }


    func test5UpdateLocation() {
        let alps = AlpsManager(apiKey: apiKey)
        let locationExpectation = expectation(description: "test5UpdateLocation")

        alps.createUser("Swift User 5") {
            (_ user) in
            if user != nil {
                alps.createMobileDevice(name: "iPhone 7", platform: "iOS 10.2",
                                    deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb665",
                                    latitude: 37.7858, longitude: -122.4064, altitude: 100,
                                    horizontalAccuracy: 5.0, verticalAccuracy: 5.0) {
                    (_ device) in
                    if let d = device {
                        if let deviceId = d.id {
                            alps.updateLocation(latitude: 38.00, longitude: -123, altitude: 100,
                                                  horizontalAccuracy: 5.0, verticalAccuracy: 5.0) {
                                (_ location) in
                                XCTAssertNotNil(location)
                                
                                // Test each fields
                                if let l = location{
                                    XCTAssertEqual(l.latitude, 38.00, "test5UpdateLocation(): Returned latitude is not equal to defined one.")
                                    XCTAssertEqual(l.longitude, -123, "test5UpdateLocation(): Returned longitude is not equal to defined one.")
                                    XCTAssertEqual(l.altitude, 100, "test5UpdateLocation(): Returned altitude is not equal to defined one.")
//                                    XCTAssertEqual(l.horizontalAccuracy, 5.0, "test5UpdateLocation(): Returned horizontalAccuracy is not equal to defined one.")
//                                    XCTAssertEqual(l.verticalAccuracy, 5.0, "test5UpdateLocation(): Returned verticalAccuracy is not equal to defined one.")
                                } else {
                                    XCTFail("test5UpdateLocation(): location is nil.")
                                }
                                locationExpectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func test6CreatePinDevice() {
        let alps = AlpsManager(apiKey: apiKey)
        let deviceExpectation = expectation(description: "test6CreatePinDevice")
        
        
        alps.createUser("Swift User 6") {
            (_ user) in
            if let _ = user {
                alps.createPinDevice(name: "SDK pin device",
                                        latitude: 37.7858, longitude: -122.4064, altitude: 100,
                                        horizontalAccuracy: 5.0, verticalAccuracy: 5.0) {
                                            (_ device) in
                                            XCTAssertNotNil(device, "Whoops, no device")
                                            // Test each fields
                                            if let deviceType = device?.deviceType?.rawValue {
                                                XCTAssertEqual(deviceType, "PinDevice", "test6CreatePinDevice(): deviceType is not equal to right type.")
                                            } else {
                                                XCTFail("test6CreatePinDevice(): deviceType is nil.")
                                            }
                                            XCTAssertNotNil(device?.id, "test6CreatePinDevice(): id is nil.")
                                            if let name = device?.name {
                                                XCTAssertEqual(name, "SDK pin device", "test6CreatePinDevice(): Returned name is not equal to defined one.")
                                            } else {
                                                XCTFail("test6CreatePinDevice(): name is nil.")
                                            }
                                            if let location = device?.location {
                                                XCTAssertEqual(location.latitude, 37.7858, "test6CreatePinDevice(): Returned latitude is not equal to defined one.")
                                                XCTAssertEqual(location.longitude, -122.4064, "test6CreatePinDevice(): Returned longitude is not equal to defined one.")
                                                XCTAssertEqual(location.altitude, 100.0, "test6CreatePinDevice(): Returned altitude is not equal to defined one.")
//                                                XCTAssertEqual(location.horizontalAccuracy, 5.0, "test6CreatePinDevice(): Returned horizontalAccuracy is not equal to defined one.")
//                                                XCTAssertEqual(location.verticalAccuracy, 5.0, "test6CreatePinDevice(): Returned verticalAccuracy is not equal to defined one.")
                                            } else {
                                                XCTFail("test6CreatePinDevice(): location is nil.")
                                            }
                                            deviceExpectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func test7CreateIBeaconDevice() {
        let alps = AlpsManager(apiKey: apiKey)
        let deviceExpectation = expectation(description: "test7CreateIBeaconDevice")
        
        
        alps.createUser("Swift User 7") {
            (_ user) in
            if let _ = user {
                alps.createIBeaconDevice(name: "SDK iBeacon device",
                                         proximityUUID: "B9407F30-F5F8-466E-AFF9-25556B57FE6D", major: 21978, minor: 59907) {
                                            (_ device) in
                                            XCTAssertNotNil(device, "Whoops, no device")
                                            // Test each fields
                                            if let deviceType = device?.deviceType?.rawValue {
                                                XCTAssertEqual(deviceType, "IBeaconDevice", "test7CreateIBeaconDevice(): deviceType is not equal to right type.")
                                            } else {
                                                XCTFail("test7CreateIBeaconDevice(): deviceType is nil.")
                                            }
                                            XCTAssertNotNil(device?.id, "test7CreateIBeaconDevice(): id is nil.")
                                            if let name = device?.name {
                                                XCTAssertEqual(name, "SDK iBeacon device", "test7CreateIBeaconDevice(): Returned name is not equal to defined one.")
                                            } else {
                                                XCTFail("test7CreateIBeaconDevice(): name is nil.")
                                            }
                                            if let proximityUUID = device?.proximityUUID {
                                                XCTAssertEqual(UUID.init(uuidString: proximityUUID), UUID.init(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D"), "test7CreateIBeaconDevice(): Returned proximityUUID is not equal to defined one.")
                                            } else {
                                                XCTFail("test7CreateIBeaconDevice(): proximityUUID is nil.")
                                            }
                                            if let major = device?.major {
                                                XCTAssertEqual(major, 21978, "test7CreateIBeaconDevice(): Returned major is not equal to defined one.")
                                            } else {
                                                XCTFail("test7CreateIBeaconDevice(): major is nil.")
                                            }
                                            if let minor = device?.minor {
                                                XCTAssertEqual(minor, 59907, "test7CreateIBeaconDevice(): Returned minor is not equal to defined one.")
                                            } else {
                                                XCTFail("test7CreateIBeaconDevice(): minor is nil.")
                                            }
                                            deviceExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    // DUMMY Test to be replaced with API Calls
    func test8GetBeacons() {
        let alps = AlpsManager(apiKey: apiKey)
        XCTAssertNotNil(alps.beacons)
        XCTAssertEqual(alps.beacons.count, 3, "Number of Dummy beacons should be 3.")
    }

    /*
     // XXX: still not found a way to allow location updates from tests
     // http://stackoverflow.com/questions/40033185/how-to-access-calendar-camera-etc-from-tests
     func test6ContinouslyUpdatingLocation() {
     let alps = AlpsManager(apiKey: apiKey)
     let deviceTemplate = Device(name: "Alps Test Device 5",
     platform: "iOS 9.3",
     deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb665")

     let locationExpectation = expectation(description: "UpdateLocation")

     alps.createUser("Swift User 5") {
     (_ user) in
     if let u = user {
     // alps.createDevice(deviceTemplate, for: u) {
     alps.createDevice(deviceTemplate) {
     (_ device) in
     if let d = device {
     alps.startUpdatingLocation()
     /*
     let newLocation = DeviceLocation(deviceId: d.deviceId!,
     altitude: 0,
     latitude: 37.785833999999994,
     longitude: -122.406417)
     alps.updateLocation(newLocation, for: u, on: d) {
     (_ location) in
     XCTAssertNotNil(location)
     locationExpectation.fulfill()
     }
     */
     }
     }
     }
     }

     waitForExpectations(timeout: 5.0, handler: nil)
     alps.stopUpdatingLocation()
     }
     */
}
