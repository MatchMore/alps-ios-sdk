//
//  PinDeviceAsyncRepoTests.swift
//  AlpsSDKTests
//
//  Created by Maciej Burda on 18/10/2017.
//  Copyright © 2017 Alps. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import AlpsSDK
@testable import Alps

class PinDeviceAsyncRepoTests: QuickSpec {
    
    func setupAPI() {
        let headers = [
            "api-key": "c9b9601d-55b9-4057-8331-f1e2c72d308d",
            "Content-Type": "application/json"
            ]
        AlpsAPI.customHeaders = headers
        AlpsAPI.basePath = "http://localhost:9000/v4"
    }
    
    let kWaitTimeInterval = 10.0
    
    override func spec() {
        setupAPI()
        let pinDeviceRepository = PinDeviceRepository()
        var createdPinDevice: PinDevice?
        
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
                            createdPinDevice = pinDevice
                        }
                        done()
                    })
                }
                expect(createdPinDevice).toEventuallyNot(beNil())
            }
            fit("read") {
                waitUntil(timeout: self.kWaitTimeInterval) { done in
                    pinDeviceRepository.find(byId: createdPinDevice!.id!,
                                             completion: { (result) in
                        if case let .success(pinDevice) = result {
                            createdPinDevice = pinDevice
                        }
                        done()
                    })
                }
                expect(createdPinDevice).toEventuallyNot(beNil())
            }
            fit("delete") {
                var deleteError: Error?
                waitUntil(timeout: self.kWaitTimeInterval) { done in
                    pinDeviceRepository.delete(item: createdPinDevice!,
                                               completion: { (error) in
                        deleteError = error
                        done()
                    })
                }
                expect(deleteError).toEventually(beNil())
            }
        }
    }
}