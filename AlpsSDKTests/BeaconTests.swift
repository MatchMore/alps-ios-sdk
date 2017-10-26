//
//  BeaconTests.swift
//  AlpsSDK
//
//  Created by Wen on 04.08.17.
//  Copyright © 2017 Alps. All rights reserved.
//

import XCTest
@testable import AlpsSDK
@testable import Alps

class BeaconTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // This test should implement asynchronous call to get the beacons and construct a beacon object
    func testCreateBeacon() {
        // 1. given
        let b = IBeaconDevice.init(name: "beacon1 - rose", proximityUUID: "B9407F30-F5F8-466E-AFF9-25556B57FE6D", major: 21978, minor: 59907)
        
        // 3. should equal
        XCTAssertTrue(b.name == "beacon1 - rose")
        XCTAssertTrue(b.proximityUUID == "B9407F30-F5F8-466E-AFF9-25556B57FE6D")
        XCTAssertTrue(b.major == 21978)
        XCTAssertTrue(b.minor == 59907)
    }
    
}
