//
//  DeviceTest.swift
//  AlpsAPI
//
//  Created by Rafal Kowalski on 24/08/17.
//  Copyright © 2017 Alps. All rights reserved.
//

import XCTest
@testable import Alps
@testable import AlpsSDK

class DeviceTest: XCTestCase {

    override func setUp() {
        super.setUp()
      }

    override func tearDown() {
        super.tearDown()
    }

   func test1DeviceInit() {
        let location = Location.init(latitude: 37.7858, longitude: 122.4064, altitude: 200.0, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        let mobileDevice = MobileDevice.init(name: "Alps iPhone 7", platform: "iOS 9.3",
                                             deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb662", location: location)

       XCTAssertNotNil(mobileDevice)
   }

   func test2DeviceInit() {
        let location = Location.init(latitude: 37.7858, longitude: 122.4064, altitude: 200.0, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        let pinDevice = PinDevice(name: "Pin 1", location: location)

        XCTAssertNotNil(pinDevice)
   }

   func test3DeviceEncodeToJSON() {
        let location = Location.init(latitude: 37.7858, longitude: 122.4064, altitude: 200.0, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
        let mobileDevice = MobileDevice.init(name: "Alps iPhone 7", platform: "iOS 9.3",
                                             deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb662", location: location)

       XCTAssertNotNil(mobileDevice)

       print("json: \(mobileDevice.encodeToJSON())")
       // TOOD: Add json string we're expecting and use XCTAssert to verify it!
       // XXX: wrong!
       // let json = ["name": "Alps iPhone 7", "deviceToken": "870470ea-7a8e-11e6-b49b-5358f3beb662", "location": ["latitude": 37.785800000000002, "verticalAccuracy": 5.0, "horizontalAccuracy": 5.0, "longitude": 122.4064, "altitude": 200.0], "platform": "iOS 9.3"]
   }

   func test4DeviceEncodeToJSON() {
       let location = Location.init(latitude: 37.7858, longitude: 122.4064, altitude: 200.0, horizontalAccuracy: 5.0, verticalAccuracy: 5.0)
       let mobileDevice = MobileDevice.init(name: "Alps iPhone 7", platform: "iOS 9.3",
                                            deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb662", location: location)
       XCTAssertNotNil(mobileDevice)

       print("json: \(mobileDevice.encodeToJSON())")
       print("valid: \(JSONSerialization.isValidJSONObject(mobileDevice.encodeToJSON()))")

       // TOOD: Add json string we're expecting and use XCTAssert to verify it!
       // XXX: wrong!
       // let json = ["name": "Alps iPhone 7", "deviceToken": "870470ea-7a8e-11e6-b49b-5358f3beb662", "location": ["latitude": 37.785800000000002, "verticalAccuracy": 5.0, "horizontalAccuracy": 5.0, "longitude": 122.4064, "altitude": 200.0], "platform": "iOS 9.3"]
   }
}
