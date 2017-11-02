//
//  PinDeviceRepositoryTests.swift
//  AlpsSDKTests
//
//  Created by Maciej Burda on 18/10/2017.
//  Copyright © 2017 Alps. All rights reserved.
//

import Foundation

import Nimble
import Quick

@testable import AlpsSDK
@testable import Alps

class PinDeviceRepositoryTests: QuickSpec {
    
    func setupAPI() {
        let headers = [
            "api-key": "2d07d184-f559-48e9-9fe7-5bb5d4d44cea",
            "Content-Type": "application/json"
            ]
        AlpsAPI.customHeaders = headers
        AlpsAPI.basePath = "http://localhost:9000/v4"
    }
    
    let kWaitTimeInterval = 10.0
    
    override func spec() {
        setupAPI()
        let pinDeviceRepository = PinDeviceRepository()
        var createdPinDeviceId: String = ""
        
        context("pin device") {
            fit ("create") {
                waitUntil(timeout: self.kWaitTimeInterval) { done in
                    let pinDevice = PinDevice(
                        name: "Test Pin",
                        location: Location(
                            latitude: 12,
                            longitude: 12,
                            altitude: 12,
                            horizontalAccuracy: 10,
                            verticalAccuracy: 10
                        )
                    )
                    pinDeviceRepository.create(item: pinDevice, 
                                               completion: { (result) in
                        if case let .success(pinDevice) = result {
                            createdPinDeviceId = pinDevice?.id ?? ""
                        }
                        done()
                    })
                }
                expect(pinDeviceRepository.items.first).toEventuallyNot(beNil())
            }
            
            var readPinDevice: PinDevice?
            fit("read") {
                waitUntil(timeout: self.kWaitTimeInterval) { done in
                    pinDeviceRepository.find(byId: createdPinDeviceId,
                                             completion: { (result) in
                        if case let .success(pinDevice) = result {
                            readPinDevice = pinDevice
                        }
                        done()
                    })
                }
                expect(readPinDevice).toEventuallyNot(beNil())
            }
            
            fit("delete") {
                waitUntil(timeout: self.kWaitTimeInterval) { done in
                    guard let readPinDevice = readPinDevice else { done(); return }
                    pinDeviceRepository.delete(item: readPinDevice,
                                               completion: { (_) in
                        done()
                    })
                }
                expect(pinDeviceRepository.items.first).toEventually(beNil())
            }
        }
    }
}