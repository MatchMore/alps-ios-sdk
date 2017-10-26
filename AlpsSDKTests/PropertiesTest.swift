//
//  PropertiesTest.swift
//  AlpsAPI
//
//  Created by Rafal Kowalski on 09/03/17.
//  Copyright © 2017 Alps. All rights reserved.
//

import XCTest

@testable import Alps

class PropertiesTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

//    func test1PropertiesInit() {
//        let properties = Properties()
//
//        XCTAssertNotNil(properties)
//    }
//
//    func test2PropertiesInit() {
//        let dictionary = ["mood": "happy"]
//
//        var properties = Properties()
//        properties["mood"] = "happy"
//
//        XCTAssertNotNil(properties)
//        XCTAssertEqual(properties, dictionary)
//    }
//
//    func test3PropertiesEncodeToJSON() {
//        let dictionary = ["mood": "happy"]
//        let properties = Properties(dictionaryLiteral: ("mood", "happy"))
//
//        XCTAssertNotNil(properties)
//        XCTAssertEqual(properties, dictionary)
//
//        print("json: \(properties.encodeToJSON())")
//    }
//
//    func test4PropertiesEncodeToJSON() {
//        let dictionary = ["mood": "happy", "energy": "high"]
//        let properties = Properties(dictionaryLiteral: ("mood", "happy"), ("energy", "high"))
//
//        XCTAssertNotNil(properties)
//        XCTAssertEqual(properties, dictionary)
//
//        print("json: \(properties.encodeToJSON())")
//        print("valid: \(JSONSerialization.isValidJSONObject(properties.encodeToJSON()))")
//        do {
//            let data = try JSONSerialization.data(withJSONObject: properties.encodeToJSON(), options: [])
//            print("data: \(data)")
//        } catch {
//            print("error")
//        }
//    }
}
