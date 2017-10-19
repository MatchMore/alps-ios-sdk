
//
//  ModelExtensions.swift
//  Alps
//
//  Created by Rafal Kowalski on 04/10/2016
//  Copyright © 2016 Alps. All rights reserved.
//

import Foundation
import Alps
import CoreLocation

extension Dictionary {
    mutating func merge(with dictionary: Dictionary) {
        dictionary.forEach { updateValue($1, forKey: $0) }
    }

    func merged(with dictionary: Dictionary) -> Dictionary {
        var dict = self
        dict.merge(with: dictionary)
        return dict
    }
}

extension User {
    internal convenience init(name: String) {
        self.init()
        self.name = name
    }

    // XXX: The  problem is  we cannot  have a  stored property  in an
    // extension  so where  should we  store the  created device?   It
    // could help if we somehow always get the AlpsManager reference
    // to store the values...
    /*
    public func createDevice(_ device: Device, completion: @escaping (_ device: Device?) -> Void) {
        let f = completion
        let _ = Alps.UserAPI.createDevice(userId: self.userId!, device: device, completion: {
            (device, error) -> Void in

            if let d = device {
                self.devices.append(d)
            }

            f(device)
        })
    }
    */
}

//extension Device {
//
//    // Device(deviceId: UUID().uuidString, name: "Alps Test Device 1",
//    // platform: "iOS 9.3", deviceToken: "870470ea-7a8e-11e6-b49b-5358f3beb662")
//
//    public convenience init(name: String) {
//        self.init()
//        self.deviceId = UUID().uuidString
//        self.name = name
//    }
//}

extension IBeaconDevice {
    //TOCHANGE: put it in internal when beaconManager is working.
    public convenience init(name: String, proximityUUID: String, major: NSNumber, minor: NSNumber){
        self.init()
        self.name = name
        self.deviceType = DeviceType.ibeacondevice
        self.proximityUUID = proximityUUID
        self.major = major as? Int32
        self.minor = minor as? Int32
    }
}

extension MobileDevice {
    internal convenience init(name:String, platform: String, deviceToken: String, location: Location?){
        self.init()
        self.name = name
        self.deviceType = DeviceType.mobileDevice
        self.platform = platform
        self.deviceToken = deviceToken
        self.location = location
    }
}

extension PinDevice {
    internal convenience init(name: String, location: Location){
        self.init()
        self.name = name
        self.deviceType = DeviceType.pinDevice
        self.location = location
    }
}

//extension DeviceLocation {
//
//    internal convenience init(deviceId: String, altitude: Double, latitude: Double, longitude: Double) {
//        self.init()
//        self.deviceId = deviceId
//        // XXX: use now for the timestamp
//        // XXX: use some defaults horizontal and vertical accuracy
//        let location = Location.init(latitude: latitude, longitude: longitude, altitude: altitude, horizontalAccuracy: 5, verticalAccuracy: 5)
//        self.location = location
//    }
//}

extension Publication {

    internal convenience init(deviceId: String, topic: String, range: Double, duration: Double, properties: [String:String]) {
        self.init()
        // XXX: use the deviceId of the DeviceLocation provided
        self.deviceId = deviceId
        self.topic = topic
        self.range = range
        self.duration = duration
        self.properties = properties
    }
}

extension Subscription {

    internal convenience init(deviceId: String, topic: String, range: Double, duration: Double, selector: String) {

        self.init()
        // XXX: use now for the timestamp
        self.deviceId = deviceId
        self.topic = topic
        self.range = range
        self.duration = duration
        self.selector = selector
    }
}

extension Location {
    
    internal convenience init(latitude: Double, longitude: Double, altitude: Double, horizontalAccuracy: Double, verticalAccuracy: Double){
        self.init()
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
    }
}

extension Match: CustomStringConvertible, Hashable {

    // XXX: take the hashValue based on the hashValue of matchId
    public var hashValue: Int {
        return id!.hashValue
    }

    // XXX: Define the match equality based on the matchId only
    public static func ==(lhs: Match, rhs: Match) -> Bool {
        return lhs.id! == rhs.id!
    }

    public var description: String {
        return "Match: (\(id!), \(createdAt!))"
    }
}

extension ProximityEvent {
    
    public convenience init(deviceId : String, distance: Double){
        self.init()
        self.deviceId = deviceId
        self.distance = distance
    }
}

extension CLProximity{
    
    static let allValues = [unknown, immediate, near, far]
}

/*
extension Payload: JSONEncodable {
    public var dictionary = [String:String]()

    public init() {}

    public init(dictionary: [String: String]) {
        self.dictionary = dictionary
    }

    // MARK: JSONEncodable
    internal func encodeToJSON() -> Any {
        var nillableDictionary = [String:Any?]()
        for (key, value) in self.dictionary {
            nillableDictionary[key] = value
        }

        return APIHelper.rejectNil(nillableDictionary) ?? [:]
    }
}
*/
