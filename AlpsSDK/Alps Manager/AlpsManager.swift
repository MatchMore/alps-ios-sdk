//
//  AlpsManager.swift
//  Alps
//
//  Created by Rafal Kowalski on 04/10/2016
//  Copyright © 2016 Alps. All rights reserved.
//

import Foundation
import CoreLocation
import Alps

public typealias OnMatchClosure = (_ matches: [Match], _ device: Device) -> Void

public protocol AlpsManagerDelegate: class {
    var onMatch: OnMatchClosure { get }
}

public class AlpsManager: MatchMonitorDelegate, ContextManagerDelegate {
    public var delegates = MulticastDelegate<AlpsManagerDelegate>()
    
    let apiKey: String
    var baseURL: String {
        set {
            AlpsAPI.basePath = newValue
        } get {
            return AlpsAPI.basePath
        }
    }
    
    public lazy var contextManager = ContextManager(delegate: self)
    public lazy var matchMonitor = MatchMonitor(delegate: self)
    
    public var remoteNotificationManager: RemoteNotificationManager!
    
    public lazy var mobileDevices: MobileDeviceRepository = {
        let mobileDevices = MobileDeviceRepository()
        mobileDevices.delegates += publications
        mobileDevices.delegates += subscriptions
        return mobileDevices
    }()
    public lazy var pinDevices: PinDeviceRepository = {
        let pinDevices = PinDeviceRepository()
        pinDevices.delegates += publications
        pinDevices.delegates += subscriptions
        return pinDevices
    }()
    
    public lazy var publications = PublicationRepository()
    public lazy var subscriptions = SubscriptionRepository()
    
    public lazy var locationUpdateManager = LocationUpdateManager()

    internal init(apiKey: String, baseURL: String? = nil) {
        self.apiKey = apiKey
        self.setupAPI()
        if let baseURL = baseURL {
            self.baseURL = baseURL
        }
        remoteNotificationManager = RemoteNotificationManager(delegate: matchMonitor)
    }
    
    private func setupAPI() {
        let device = UIDevice.current
        let headers = [
            "api-key": self.apiKey,
            "Content-Type": "application/json; charset=UTF-8",
            "Accept": "application/json",
            "user-agent": "\(device.systemName) \(device.systemVersion)"
        ]
        AlpsAPI.customHeaders = headers
    }
    
    // MARK: - Match Monitor Delegate
    
    func didFind(matches: [Match], for device: Device) {
        delegates.invoke { $0.onMatch(matches, device) }
    }
    
    // MARK: - Context Manager Delegate
    
    func didUpdateLocation(location: CLLocation) {
        mobileDevices.findAll { (result) in
            guard case let .success(mobileDevices) = result else { return }
            mobileDevices.forEach {
                guard let deviceId = $0.id else { return }
                self.locationUpdateManager.tryToSend(location: Location(location: location), for: deviceId)
            }
        }
    }

}