//
//  AlpsAPITests.swift
//  AlpsAPITests
//
//  Created by Rafal Kowalski on 01/09/16.
//  Copyright © 2016 Alps. All rights reserved.
//

import XCTest
@testable import Alps
@testable import AlpsSDK
import Alamofire

class AlpsAPITests: XCTestCase {
    let headers = [
        "user-agent": "iOS 9.3.0",
        "api-key": "ea0df90a-db0a-11e5-bd35-3bd106df139b",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "application/json, text/plain"
    ]

    let now = { Int64(Date().timeIntervalSince1970 * 1000) }

    override func setUp() {
        super.setUp()
        // AlpsAPI.basePath = "http://localhost:9000"
        AlpsAPI.basePath = "https://api.matchmore.io/v4"
        AlpsAPI.customHeaders = headers
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func createUser() -> User? {
        var createdUser: User?
        let expectation = self.expectation(description: "CreateUser")
        let user = User.init(name: "Alps User 1")
        let _ = Alps.UsersAPI.createUser(user: user, completion: {
            (user, error) -> Void in
            
            createdUser = user
            XCTAssertNil(error, "Whoops, error \(String(describing: error))")
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5.0, handler: nil)

        return createdUser
    }
    
    func createMobileDevice(_ user: User) -> MobileDevice? {
        let deviceExpectation = expectation(description: "CreateMobileDevice")
        
        var createdDevice: MobileDevice?
        let location = Location.init(latitude: 37.7858, longitude: 122.4064, altitude: 200.0, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        let mobileDevice = MobileDevice.init(name: "Alps iPhone 7", platform: "iOS 9.3",deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb662", location: location)
        if let userId = user.id{
            let _ = Alps.UserAPI.createDevice(userId: userId, device: mobileDevice) {
                                                (device, error) -> Void in
                
                
                                                XCTAssertNil(error, "Whoops, error \(String(describing: error))")
                                                createdDevice = device as? MobileDevice
                                                deviceExpectation.fulfill()
            }
        } else {
            XCTFail("createMobileDevice() : userId is nil.")
        }
        waitForExpectations(timeout: 5.0, handler: nil)
        
        return createdDevice
    }
    
    func createPinDevice(_ user: User) -> PinDevice? {
        let deviceExpectation = expectation(description: "CreatePinDevice")
        
        var createdDevice: PinDevice?
        let location = Location.init(latitude: 37.7858, longitude: 122.4064, altitude: 200.0, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        let pinDevice = PinDevice.init(name: "Alps pin 1", location: location)
        if let userId = user.id {
            let _ = Alps.UserAPI.createDevice(userId: userId, device: pinDevice) {
                                                        (device, error) -> Void in
                
                                                        XCTAssertNil(error, "Whoops, error \(String(describing: error))")
                                                        createdDevice = device as? PinDevice
                                                        deviceExpectation.fulfill()
            }
        } else {
            XCTFail("createPinDevice(): userId is nil.")
        }
        waitForExpectations(timeout: 5.0, handler: nil)
        
        return createdDevice
    }
    
    func createIBeaconDevice(_ user: User) -> IBeaconDevice? {
        let deviceExpectation = expectation(description: "CreateIBeaconDevice")
        
        var createdDevice: IBeaconDevice?
        let iBeaconDevice = IBeaconDevice.init(name: "Alps iBeacon 1", proximityUUID: "B9407F30-F5F8-466E-AFF9-25556B57FE6D", major: 10, minor: 10)
        if let userId = user.id {
            let _ = Alps.UserAPI.createDevice(userId: userId, device: iBeaconDevice) {
                                                    (device, error) -> Void in
                                                    
                                                    XCTAssertNil(error, "Whoops, error \(String(describing: error))")
                                                    createdDevice = device as? IBeaconDevice
                                                    deviceExpectation.fulfill()
            }
        } else {
            XCTFail("createIBeaconDevice(): userId is nil.")
        }
        waitForExpectations(timeout: 5.0, handler: nil)
        
        return createdDevice
    }

    func createPublication(_ user: User,_ device: Device) -> Publication? {
        var createdPublication: Publication?

        let pubExpectation = expectation(description: "CreatePub")

//         let properties = Properties(dictionaryLiteral: ("role", "'developer'"))
        let properties = ["role": "'developer'"]

        if let userId = user.id, let deviceId = device.id {
            let publication = Publication.init(deviceId: deviceId, topic: "alps-test", range: 100.0, duration: 0.0, properties: properties)
            let _ = Alps.DeviceAPI.createPublication(userId: userId, deviceId: deviceId, publication: publication) {
                (publication, error) -> Void in

                XCTAssertNil(error, "Whoops, error \(String(describing: error))")
                createdPublication = publication
                pubExpectation.fulfill()
            }
        } else {
            XCTFail("createPublication(): Error userId or deviceId is nil.")
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        return createdPublication
    }

    func createSubscription(_ user: User,_ device: Device) -> Subscription? {
        var createdSubscription: Subscription?

        let subExpectation = expectation(description: "CreateSub")
        let selector = "role = 'developer'"
        if let userId = user.id, let deviceId = device.id {
            let subscription = Subscription.init(deviceId: deviceId, topic: "alps-test", range: 100.0, duration: 0.0, selector: selector)
            let _ = Alps.DeviceAPI.createSubscription(userId: userId, deviceId: deviceId, subscription: subscription) {
                                                        (subscription, error) -> Void in
                                                            XCTAssertNil(error, "Whoops, error \(String(describing: error))")
                                                            createdSubscription = subscription
                                                            subExpectation.fulfill()
            }
        } else {
            XCTFail("createSubscription(): Error userId or deviceId is nil.")
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        return createdSubscription
    }

    func createLocation(_ user: User,_ device: Device) -> Location? {
        let locationExpectation = expectation(description: "CreateLocation")
        var createdLocation: Location?

        let location = Location.init(latitude: 37.7858, longitude: -122.4064, altitude: 20.0,horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        if let userId = user.id, let deviceId = device.id {
            let _ = Alps.DeviceAPI.createLocation(userId: userId, deviceId: deviceId, location: location) {
                    (location, error) -> Void in
                        XCTAssertNil(error, "Whoops, error \(String(describing: error))")
                        createdLocation = location
                        locationExpectation.fulfill()
            }
        } else {
            XCTFail("createLocation(): Error userId or deviceId is nil.")
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        return createdLocation
    }

    func getMatches(_ user: User,_ device: Device) -> [Match]? {
        let matchExpectation = expectation(description: "GetMatches")
        var gotMatches: [Match]?
        if let userId = user.id, let deviceId = device.id {
            let _ = Alps.DeviceAPI.getMatches(userId: userId, deviceId: deviceId) {
                (matches, error) -> Void in

                XCTAssertNil(error, "Whoops, error \(String(describing: error))")
                gotMatches = matches
                matchExpectation.fulfill()
            }
        } else {
            XCTFail("getMatches(): Error userId or deviceId is nil.")
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        return gotMatches
    }

    func test1Alamofire() {
        let expectation = self.expectation(description: "Alamofire")

        Alamofire.request(AlpsAPI.basePath.appending("/ping"), headers: headers)
            .validate(statusCode: 200..<300)
            .responseString { response in
                print("Success: \(response.result.isSuccess)")
                XCTAssert(response.result.isSuccess, "Status code not 200")
                print("Response String: \(String(describing: response.result.value))")

                expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }


    func test2CreateUser() {
        let user = createUser()
        XCTAssertNotNil(user)
        XCTAssertNotNil(user?.id, "test2CreateUser(): id is nil.")
        if let name = user?.name {
            XCTAssertEqual(name, "Alps User 1", "test2CreateUser(): Returned name is not equal to defined one.")
        } else {
            XCTFail("test2CreateUser(): name is nil.")
        }
    }
    
    func test3CreateMobileDevice() {
        if let user = createUser() {
            let device = createMobileDevice(user)
            XCTAssertNotNil(device)
            
            // Test each fields
            if let deviceType = device?.deviceType?.rawValue {
                XCTAssertEqual(deviceType, "MobileDevice", "createMobileDevice(): deviceType is not equal to right type.")
            } else {
                XCTFail("test3CreateMobileDevice(): deviceType is nil.")
            }
            XCTAssertNotNil(device?.id, "test3CreateMobileDevice(): id is nil.")
            if let name = device?.name {
                XCTAssertEqual(name, "Alps iPhone 7", "test3CreateMobileDevice(): Returned name is not equal to defined one.")
            } else {
                XCTFail("test3CreateMobileDevice(): name is nil.")
            }
            if let platform = device?.platform {
                XCTAssertEqual(platform, "iOS 9.3", "test3CreateMobileDevice(): Returned platform is not equal to defined one.")
            } else {
                XCTFail("test3CreateMobileDevice(): platform is nil.")
            }
            if let deviceToken = device?.deviceToken {
                XCTAssertEqual(deviceToken, "870470ea-7a8e-11e6-b49b-5358f3beb662", "test3CreateMobileDevice(): Returned deviceToken is not equal to defined one.")
            } else {
                XCTFail("test3CreateMobileDevice(): deviceToken is nil.")
            }
            if let location = device?.location {
                XCTAssertEqual(location.latitude, 37.7858, "test3CreateMobileDevice(): Returned latitude is not equal to defined one.")
                XCTAssertEqual(location.longitude, 122.4064, "test3CreateMobileDevice(): Returned longitude is not equal to defined one.")
                XCTAssertEqual(location.altitude, 200.0, "test3CreateMobileDevice(): Returned altitude is not equal to defined one.")
//                XCTAssertEqual(location.horizontalAccuracy, 5.0, "test3CreateMobileDevice(): Returned horizontalAccuracy is not equal to defined one.")
//                XCTAssertEqual(location.verticalAccuracy, 5.0, "test3CreateMobileDevice(): Returned verticalAccuracy is not equal to defined one.")
            } else {
                XCTFail("test3CreateMobileDevice(): location is nil.")
            }
        } else {
            XCTFail("test3CreateMobileDevice(): No returned user.")
        }
    }
    
    func test4CreatePinDevice() {
        if let user = createUser() {
            let device = createPinDevice(user)
            XCTAssertNotNil(device)
            
            // Test each fields
            if let deviceType = device?.deviceType?.rawValue {
                XCTAssertEqual(deviceType, "PinDevice", "test4CreatePinDevice(): deviceType is not equal to right type.")
            } else {
                XCTFail("test4CreatePinDevice(): deviceType is nil.")
            }
            XCTAssertNotNil(device?.id, "test4CreatePinDevice(): id is nil.")
            if let name = device?.name {
                XCTAssertEqual(name, "Alps pin 1", "test4CreatePinDevice(): Returned name is not equal to defined one.")
            } else {
                XCTFail("test4CreatePinDevice(): name is nil.")
            }
            if let location = device?.location {
                XCTAssertEqual(location.latitude, 37.7858, "test4CreatePinDevice(): Returned latitude is not equal to defined one.")
                XCTAssertEqual(location.longitude, 122.4064, "test4CreatePinDevice(): Returned longitude is not equal to defined one.")
                XCTAssertEqual(location.altitude, 200.0, "test4CreatePinDevice(): Returned altitude is not equal to defined one.")
//                XCTAssertEqual(location.horizontalAccuracy, 5.0, "test4CreatePinDevice(): Returned horizontalAccuracy is not equal to defined one.")
//                XCTAssertEqual(location.verticalAccuracy, 5.0, "test4CreatePinDevice(): Returned verticalAccuracy is not equal to defined one.")
            } else {
                XCTFail("test4CreatePinDevice(): location is nil.")
            }
        } else {
            XCTFail("test4CreatePinDevice(): No returned user.")
        }
    }
    
    func test5CreateBeaconDevice() {
        if let user = createUser() {
            let device = createIBeaconDevice(user)
            XCTAssertNotNil(device)
            
            // Test each fields
            if let deviceType = device?.deviceType?.rawValue {
                XCTAssertEqual(deviceType, "IBeaconDevice", "test5CreateIBeaconDevice(): deviceType is not equal to right type.")
            } else {
                XCTFail("test5CreateIBeaconDevice(): deviceType is nil.")
            }
            XCTAssertNotNil(device?.id, "test5CreateIBeaconDevice(): id is nil.")
            if let name = device?.name {
                XCTAssertEqual(name, "Alps iBeacon 1", "test5CreateIBeaconDevice(): Returned name is not equal to defined one.")
            } else {
                XCTFail("test5CreateIBeaconDevice(): name is nil.")
            }
            if let proximityUUID = device?.proximityUUID {
                XCTAssertEqual(UUID.init(uuidString: proximityUUID), UUID.init(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D"), "test5CreateIBeaconDevice(): Returned proximityUUID is not equal to defined one.")
            } else {
                XCTFail("test5CreateIBeaconDevice(): proximityUUID is nil.")
            }
            if let major = device?.major {
                XCTAssertEqual(major, 10, "test5CreateIBeaconDevice(): Returned major is not equal to defined one.")
            } else {
                XCTFail("test5CreateIBeaconDevice(): major is nil.")
            }
            if let minor = device?.minor {
                XCTAssertEqual(minor, 10, "test5CreateIBeaconDevice(): Returned minor is not equal to defined one.")
            } else {
                XCTFail("test5CreateIBeaconDevice(): minor is nil.")
            }
        } else {
            XCTFail("test5CreateIBeaconDevice(): No returned user.")
        }
    }

    func test6CreatePublication() {
        let properties = ["role": "'developer'"]
        if let user = createUser() {
            if let device = createMobileDevice(user) {
                let publication = createPublication(user, device)
                XCTAssertNotNil(publication)
                
                // Test each fields
                XCTAssertNotNil(publication?.id, "test6CreatePublication(): id is nil.")
                if let deviceId = publication?.deviceId {
                    XCTAssertEqual(deviceId, device.id, "test6CreatePublication(): deviceId is not equal to defined one.")
                } else {
                    XCTFail("test6CreatePublication(): deviceId is nil.")
                }
                if let topic = publication?.topic {
                    XCTAssertEqual(topic, "alps-test", "test6CreatePublication(): topic is not equal to defined one.")
                } else {
                    XCTFail("test6CreatePublication(): topic is nil.")
                }
                if let range = publication?.range {
                    XCTAssertEqual(range, 100.0, "test6CreatePublication(): range is not equal to defined one.")
                } else {
                    XCTFail("test6CreatePublication(): range is nil.")
                }
                if let duration = publication?.duration {
                    XCTAssertEqual(duration, 0.0, "test6CreatePublication(): duration is not equal to defined one.")
                } else {
                    XCTFail("test6CreatePublication(): duration is nil.")
                }
                if let testedProperties = publication?.properties {
                    XCTAssertEqual(testedProperties, properties, "test6CreatePublication(): properties is not equal to defined one.")
                } else {
                    XCTFail("test6CreatePublication(): properties is nil.")
                }
            } else {
                XCTFail("test6CreatePublication(): device was not properly created.")
            }
        } else {
            XCTFail("test6CreatePublication(): No returned user.")
        }
    }

    func test7CreateSubscription() {
        if let user = createUser() {
            if let device = createMobileDevice(user) {
                let subscription = createSubscription(user, device)
                XCTAssertNotNil(subscription)
                
                // Test each fields
                XCTAssertNotNil(subscription?.id, "test7CreateSubscription(): id is nil.")
                if let deviceId = subscription?.deviceId {
                    XCTAssertEqual(deviceId, device.id, "test7CreateSubscription(): deviceId is not equal to defined one.")
                } else {
                    XCTFail("test7CreateSubscription(): deviceId is nil.")
                }
                if let topic = subscription?.topic {
                    XCTAssertEqual(topic, "alps-test", "test7CreateSubscription(): topic is not equal to defined one.")
                } else {
                    XCTFail("test7CreateSubscription(): topic is nil.")
                }
                if let range = subscription?.range {
                    XCTAssertEqual(range, 100.0, "test7CreateSubscription(): range is not equal to defined one.")
                } else {
                    XCTFail("test7CreateSubscription(): range is nil.")
                }
                if let duration = subscription?.duration {
                    XCTAssertEqual(duration, 0.0, "test7CreateSubscription(): duration is not equal to defined one.")
                } else {
                    XCTFail("test7CreateSubscription(): duration is nil.")
                }
                if let selector = subscription?.selector {
                    XCTAssertEqual(selector, "role = 'developer'", "test7CreateSubscription(): selector is not equal to defined one.")
                } else {
                    XCTFail("test7CreateSubscription(): properties is nil.")
                }
            } else {
                XCTFail("test7CreateSubscription(): device was not properly created.")
            }
        } else {
            XCTFail("test7CreateSubscription(): No returned user.")
        }
    }

    func test8CreateLocation() {
        if let user = createUser() {
            if let device = createMobileDevice(user) {
                let location = createLocation(user, device)
                XCTAssertNotNil(location)
                
                // Test each fields
                if let deviceId = device.id {
                    XCTAssertEqual(deviceId, device.id, "test8CreateLocation(): deviceId is not equal to defined one.")
                } else {
                    XCTFail("test8CreateLocation(): deviceId is nil.")
                }
                if let l = location{
                    XCTAssertEqual(l.latitude, 37.7858, "test8CreateLocation(): Returned latitude is not equal to defined one.")
                    XCTAssertEqual(l.longitude, -122.4064, "test8CreateLocation(): Returned longitude is not equal to defined one.")
                    XCTAssertEqual(l.altitude, 20.0, "test8CreateLocation(): Returned altitude is not equal to defined one.")
//                    XCTAssertEqual(l.horizontalAccuracy, 5.0, "test8CreateLocation(): Returned horizontalAccuracy is not equal to defined one.")
//                    XCTAssertEqual(l.verticalAccuracy, 5.0, "test8CreateLocation(): Returned verticalAccuracy is not equal to defined one.")
                } else {
                    XCTFail("test8CreateLocation(): location is nil.")
                }
            } else {
                XCTFail("test8CreateLocation(): device was not properly created.")
            }
        } else {
            XCTFail("test8CreateLocation(): No returned user.")
        }
    }

    func test9GetMatches() {
        if let user = createUser() {
            if let device = createMobileDevice(user) {
                let matches = getMatches(user, device)
                XCTAssertNotNil(matches)
                
                // Test each fields
            } else {
                XCTFail("test9GetMatches(): device was not properly created.")
            }
        } else {
            XCTFail("test9GetMatches(): No returned user.")
        }
    }
}
