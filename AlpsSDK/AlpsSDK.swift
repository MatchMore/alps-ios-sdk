//
//  Alps.swift
//  AlpsSDK
//
//  Created by Rafal Kowalski on 03/10/2016
//  Copyright © 2016 Alps. All rights reserved.
//

import Foundation
import Alps
import CoreLocation

protocol AlpsSDK {

    // MARK: DYNAMIC Functions
    func getMainUser() -> User?
    func getMainDevice() -> Device?
    func getAllDevicesMainUser() -> [Device]
    func getAllLocationsMainUser() -> [String: Location]
    func getAllPublicationsMainUser(completion: @escaping (_ publications: [String:[Publication]]) -> Void)
    func getAllSubscriptionsMainUser(completion: @escaping (_ subscriptions: [String:[Subscription]]) -> Void)
    func getExistingBeacons() -> [IBeaconDevice]
    
    // MARK: API CALL Functions
    // create Alps entities
    func createUser(_ userName: String, completion: @escaping (_ user: User?) -> Void)

    // XXX: v 0.0.3: assume one user and one device in the AlpsManager for now
    // to 0.4.0 assume one user and one main device(Mobile) and many devices in the AlpsManager for now
    // Create Main device, this function replace createDevice in v 0.0.3
    func createMobileDevice(name: String, platform: String, deviceToken: String,
                      latitude: Double, longitude: Double, altitude: Double,
                      horizontalAccuracy: Double, verticalAccuracy: Double,
                      completion: @escaping (_ device: MobileDevice?) -> Void)
    // Create a pinned Device, stays at the same location
    func createPinDevice(name: String, latitude: Double, longitude: Double, altitude: Double,
                         horizontalAccuracy: Double, verticalAccuracy: Double,
                         completion: @escaping (_ device: PinDevice?) -> Void)
    // Create a BLE iBeacon Device
    func createIBeaconDevice(name: String, proximityUUID: String, major: NSNumber, minor: NSNumber,
                            completion: @escaping (_ device: IBeaconDevice?) -> Void)
    
    // create a publication for the main device
    func createPublication(topic: String, range: Double, duration: Double, properties: [String:String],
                           completion: @escaping (_ publication: Publication?) -> Void)
    // Create a publication for the given userId and given deviceId
    func createPublication(userId: String, deviceId: String, topic: String, range: Double, duration: Double, properties: [String:String],
                                  completion: @escaping (_ publication: Publication?) -> Void)

    // Create subscription for main device
    func createSubscription(topic: String, selector: String, range: Double, duration: Double,
                                   completion: @escaping (_ subscription: Subscription?) -> Void)
    // Create a subscription for the given userId and given deviceId
    func createSubscription(userId: String, deviceId: String, topic: String, selector: String, range: Double, duration: Double,
                                   completion: @escaping (_ subscription: Subscription?) -> Void)
    
    // Update main device location
    func updateLocation(latitude: Double, longitude: Double, altitude: Double,
                        horizontalAccuracy: Double, verticalAccuracy: Double,
                        completion: @escaping (_ location: Location?) -> Void)
    // register location handlers
    func onLocationUpdate(completion: @escaping ((_ location: CLLocation) -> Void))
    
    // Get all matches for main device
    func getAllMatches(completion: @escaping (_ matches: Matches) -> Void)
    // register match handlers
    func onMatch(completion: @escaping (_ match: Match) -> Void)

    // queries
    func getUser(_ userId: String, completion: @escaping (_ user: User) -> Void)
    func getDevice(_ deviceId: String, completion: @escaping (_ device: Device) -> Void)
//    func getDevice(completion: @escaping (_ device: Device) -> Void)
    func getPublication(_ userId:String, deviceId:String, publicationId: String, completion: @escaping (_ publication: Publication) -> Void)
    func deletePublication(_ userId:String, deviceId:String, publicationId: String, completion: @escaping () -> Void)
    func getAllPublicationsForDevice(_ userId:String, deviceId: String, completion: @escaping (_ publications: [Publication]) -> Void)
    func getSubscription(_ userId:String, deviceId:String, subscriptionId: String, completion: @escaping (_ subscription: Subscription) -> Void)
    func deleteSubscription(_ userId:String, deviceId:String, subscriptionId: String, completion: @escaping () -> Void)
    func getAllSubscriptionsForDevice(_ userId:String, deviceId:String, completion: @escaping (_ subscriptions: [Subscription]) -> Void)

    // delete Alps entities

    // query stats

    // start/stop function
    func startMonitoringMatches()
    func stopMonitoringMatches()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    // TBD, automation of ranging
//    func startRangingBeacons(forUuid: UUID, identifier: String)
//    func stopRangingBeacons(forUuid: UUID)
//    func startBeaconsProximityEvent(forCLProximity: CLProximity)
//    func stopBeaconsProximityEvent(forCLProximity: CLProximity)
    
    // Beacons
    func getClosestOnBeaconUpdate(completion: @escaping ((_ beacon: CLBeacon) -> Void))
    func getAllOnBeaconUpdate(completion: @escaping ((_ beacon: [CLBeacon]) -> Void))
    func setRefreshTimerForProximityEvent(refreshEveryInMilliseconds: Int)
}
