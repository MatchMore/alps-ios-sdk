//
//  ContextManager.swift
//  Alps
//
//  Created by Rafal Kowalski on 28.09.16.
//  Copyright © 2016 Alps. All rights reserved.
//

import Foundation
import CoreLocation
import Alps

class ContextManager: NSObject, CLLocationManagerDelegate {
    var alpsManager: AlpsManager
    private(set) var proximityHandler : ProximityHandler!
    var seenError = false
    var locationFixAchieved = false
    let clLocationManager: CLLocationManager

    var onLocationUpdateClosure: ((_ location: CLLocation) -> Void)?
    var closestBeaconClosure: ((_ beacon: CLBeacon) -> Void)?
    var detectedBeaconsClosure: ((_ beacons: [CLBeacon]) -> Void)?

    public func onLocationUpdate(completion: @escaping (_ location: CLLocation) -> Void) {
        onLocationUpdateClosure = completion
    }

    convenience init(alpsManager: AlpsManager) {
        self.init(alpsManager: alpsManager, locationManager: CLLocationManager())
    }

    init(alpsManager: AlpsManager, locationManager: CLLocationManager) {
        self.alpsManager = alpsManager
        self.clLocationManager = locationManager
        super.init()
        self.proximityHandler = ProximityHandler(contextManager: self)

        self.clLocationManager.delegate = self
        self.clLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.clLocationManager.requestAlwaysAuthorization()
    }

    // Location Manager Delegate stuff
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        seenError = true
        print(error)
    }

    // Update locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = locations.last {
            self.onLocationUpdateClosure?(locations.last!)
            alpsManager.updateLocation(latitude: coord.coordinate.latitude, longitude: coord.coordinate.longitude,
                                             altitude: coord.altitude, horizontalAccuracy: coord.horizontalAccuracy,
                                             verticalAccuracy: coord.verticalAccuracy) {
                    (_ location) in
                    NSLog("updating location to: \(coord.coordinate.latitude), \(coord.coordinate.longitude), \(coord.altitude)")
                }
        }
    }

    // authorization status
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var shouldAllow = false

        switch status {
        case .restricted, .denied, .notDetermined:
            shouldAllow = false
        default:
            shouldAllow = true
        }

        if (shouldAllow == true) {
            print("Location updates allowed")
            manager.startUpdatingLocation()
        } else {
            print("Location updates denied")
        }
    }

    func startUpdatingLocation() {
        clLocationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        clLocationManager.stopUpdatingLocation()
    }
    
    //DEVELOP: Beacons
    func startRanging(forUuid : UUID, identifier : String){
        let ourCLBeaconRegion = CLBeaconRegion.init(proximityUUID: forUuid, identifier: identifier)
        clLocationManager.startRangingBeacons(in: ourCLBeaconRegion)
    }
    
    func stopRanging(forUuid : UUID){
        for region in clLocationManager.rangedRegions{
            if let beaconRegion = region as? CLBeaconRegion {
                if forUuid.uuidString == beaconRegion.proximityUUID.uuidString {
                    clLocationManager.stopRangingBeacons(in: beaconRegion)
                    print("Stopped ranging for a beacon region")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // Returning the closest beacon and all the detected beacons
        var closest : CLBeacon?
        if beacons.isEmpty != true {
            closest = beacons.first!
            for beacon in beacons{
                if ((closest?.accuracy)! > beacon.accuracy) {
                    closest = beacon;
                }
            }
        }
        
        if let closestBeacon = closest {
            self.closestBeaconClosure?(closestBeacon)
            self.detectedBeaconsClosure?(beacons)
        }
        
        // Proximity Events related
        let trigger = proximityHandler.parseBeaconsByProximity(beacons)
        if trigger {
            // trigger proximity event because there is change
            proximityHandler.triggerBeaconsProximityEvent()
        }
        proximityHandler.refreshTriggers()
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(error)
    }
    
    func getClosestOnBeaconUpdate(completion: @escaping (_ beacon: CLBeacon) -> Void){
        closestBeaconClosure = completion
    }
    
    func getAllOnBeaconUpdate(completion: @escaping (_ beacons: [CLBeacon]) -> Void){
        detectedBeaconsClosure = completion
    }
    
    public func startBeaconsProximityEvent(forCLProximity: CLProximity) {
        proximityHandler.proximityTrigger.insert(forCLProximity)
    }
    
    public func stopBeaconsProximityEvent(forCLProximity: CLProximity) {
        proximityHandler.proximityTrigger.remove(forCLProximity)
    }
    
    class ProximityHandler {
        
        var contextManager : ContextManager!
        static var immediateTrigger : [String:ProximityEvent] = [:]
        static var nearTrigger : [String:ProximityEvent] = [:]
        static var farTrigger : [String:ProximityEvent] = [:]
        static var unknownTrigger : [String:ProximityEvent] = [:]
        var immediateBeacons : [String] = []
        var nearBeacons : [String] = []
        var farBeacons : [String] = []
        var unknownBeacons : [String] = []
        // Beacons
        // Triggered proximity event map
        var proximityTrigger = Set<CLProximity>()
        var refreshTimer : Int = 60 * 1000 // timer is in milliseconds
        
        init(contextManager: ContextManager) {
            self.contextManager = contextManager
        }
        
        func parseBeaconsByProximity(_ beacons: [CLBeacon]) -> Bool {
            var ourBeacon : IBeaconDevice?
            var result = false
            for beacon in beacons {
                let b = syncBeacon(beacon: beacon)
                if b.isEmpty != true {
                    ourBeacon = b[0]
                }
                if let deviceId = ourBeacon?.id{
                    let detectedBeaconChange = removeDuplicate(clBeacon: beacon, deviceId : deviceId)
                    if detectedBeaconChange == true {
                        // if one of the detected beacon did change, then we want to trigger a proximity event
                        result = true
                    }
                }
            }
            return result
        }
        
        private func syncBeacon(beacon: CLBeacon) -> [IBeaconDevice] {
            var b : [IBeaconDevice] = self.contextManager.alpsManager.beacons
            b = self.contextManager.alpsManager.beacons.filter{
                let proximityUUID = $0.proximityUUID!
                let major = $0.major!
                let minor = $0.minor!
                // it will be called the number of time of beacons registered in the app. In example : It will be called 3 times because I have 3 beacons registered.
                if (proximityUUID.caseInsensitiveCompare(beacon.proximityUUID.uuidString) == ComparisonResult.orderedSame)  && (major as NSNumber) == beacon.major && (minor as NSNumber) == beacon.minor {
                    return true
                }
                return false
            }
            return b
        }
        
        private func removeDuplicate(clBeacon: CLBeacon, deviceId : String) -> Bool {
            func removeBeacon(deviceId: String, fromArray: [String]) -> [String] {
                var beaconsId : [String] = []
                beaconsId = fromArray
                if beaconsId.contains(deviceId){
                    if let index = beaconsId.index(of: deviceId){
                        beaconsId.remove(at: index)
                    }
                }
                return beaconsId
            }
            
            func addBeacon(clBeacon: CLBeacon, deviceId: String) {
                switch clBeacon.proximity {
                case .unknown: unknownBeacons.append(deviceId)
                case .immediate: immediateBeacons.append(deviceId)
                case .near: nearBeacons.append(deviceId)
                case .far: farBeacons.append(deviceId)
                }
            }
            
            var detectedBeaconChange = false
            if immediateBeacons.contains(deviceId) || nearBeacons.contains(deviceId) || farBeacons.contains(deviceId) || unknownBeacons.contains(deviceId) {
                immediateBeacons = removeBeacon(deviceId : deviceId, fromArray: immediateBeacons)
                nearBeacons = removeBeacon(deviceId: deviceId, fromArray: nearBeacons)
                farBeacons = removeBeacon(deviceId: deviceId, fromArray: farBeacons)
                unknownBeacons = removeBeacon(deviceId: deviceId, fromArray: unknownBeacons)
                detectedBeaconChange = true
            }
            addBeacon(clBeacon: clBeacon, deviceId: deviceId)
            return detectedBeaconChange
        }
        
        private func setUpTriggerBeaconsProximityEvent(forCLProximity: CLProximity) -> ([String], [String: ProximityEvent], Double) {
            var beacons : [String]
            var trigger : [String:ProximityEvent]
            var distance : Double
            switch forCLProximity {
            case .immediate:
                beacons = immediateBeacons
                trigger = ProximityHandler.immediateTrigger
                distance = 0.5
            case .near:
                beacons = nearBeacons
                trigger = ProximityHandler.nearTrigger
                distance = 3.0
            case .far:
                beacons = farBeacons
                trigger = ProximityHandler.farTrigger
                distance = 50.0
            case .unknown:
                beacons = unknownBeacons
                trigger = ProximityHandler.unknownTrigger
                distance = 200.0
            }
            return (beacons, trigger, distance)
        }
        
        private func setTrigger(forCLProximity: CLProximity, trigger : [String:ProximityEvent]) {
            switch forCLProximity{
            case .immediate:
                ProximityHandler.immediateTrigger = trigger
            case .near:
                ProximityHandler.nearTrigger = trigger
            case .far:
                ProximityHandler.farTrigger = trigger
            case .unknown:
                ProximityHandler.unknownTrigger = trigger
            }
        }
        
        private func sendProximityEvent(userId: String, deviceId: String, proximityEvent: ProximityEvent, completion: @escaping (_ proximityEvent: ProximityEvent?) -> Void) {
            let userCompletion = completion
            let _ = Alps.DeviceAPI.triggerProximityEvents(userId: userId, deviceId: deviceId, proximityEvent: proximityEvent) {
                (proximityEvent, error) -> Void in
                userCompletion(proximityEvent)
            }
        }
        
        private func addProximityEvent(id: String, proximityEvent: ProximityEvent, clProximity: CLProximity) {
            switch clProximity {
            case .unknown: ProximityHandler.unknownTrigger[id] = proximityEvent
            case .immediate: ProximityHandler.immediateTrigger[id] = proximityEvent
            case .near: ProximityHandler.nearTrigger[id] = proximityEvent
            case .far: ProximityHandler.farTrigger[id] = proximityEvent
            }
        }
    
        func triggerBeaconsProximityEvent() {
            for clProximity in CLProximity.allValues{
                var (beacons, trigger, distance) = setUpTriggerBeaconsProximityEvent(forCLProximity: clProximity)
                for id in beacons{
                    // Check if a proximity event already exist
                    if trigger[id] == nil {
                        // Send the proximity event
                        let proximityEvent = ProximityEvent.init(deviceId: id, distance: distance)
                        let userId = self.contextManager.alpsManager.alpsUser?.user.id
                        let deviceId = self.contextManager.alpsManager.alpsDevice?.device.id
                        sendProximityEvent(userId: userId!, deviceId: deviceId!, proximityEvent: proximityEvent) {
                            (_ proximityEvent) in
                            if let pe = proximityEvent{
                                self.addProximityEvent(id: id, proximityEvent: pe, clProximity: clProximity)
                            }
                        }
                    }
                }
            }
        }
        
        func refreshTriggers() {
            for clProximity in CLProximity.allValues{
                var (beacons, trigger, distance) = setUpTriggerBeaconsProximityEvent(forCLProximity: clProximity)
                for id in beacons{
                    // Check if the existed proximity event needs a refresh on a based timer
                    let proximityEvent = trigger[id]
                    // Represents  the UNIX current time in milliseconds
                    let now = Int64(Date().timeIntervalSince1970 * 1000)
                    if let proximityEventCreatedAt = proximityEvent?.createdAt {
                        let gap = now - proximityEventCreatedAt
                        let truncatedGap = Int(truncatingBitPattern: gap)
                        if truncatedGap > refreshTimer {
                            // Send the refreshing proximity event based on the timer
                            let newProximityEvent = ProximityEvent.init(deviceId: id, distance: distance)
                            let userId = self.contextManager.alpsManager.alpsUser?.user.id
                            let deviceId = self.contextManager.alpsManager.alpsDevice?.device.id
                            sendProximityEvent(userId: userId!, deviceId: deviceId!, proximityEvent: newProximityEvent) {
                                (_ proximityEvent) in
                                if let pe = proximityEvent{
                                    self.addProximityEvent(id: id, proximityEvent: pe, clProximity: clProximity)
                                }
                            }
                        }else{
                            // Do something when it doesn't need to be refreshed
                        }
                    }
                }
            }
        }
        
        @objc
        private class func cleanUpTriggers() {
            var trigger : [String:ProximityEvent] = [:]
            func refresh(trigger: [String:ProximityEvent]){
                var t : [String:ProximityEvent] = [:]
                t = trigger
                for (id, proximityEvent) in t {
                    
                    if let createdAt = proximityEvent.createdAt {
                        let now = Int64(Date().timeIntervalSince1970 * 1000)
                        let gap = now - createdAt
                        
                        // If gap is higher than 5 minutes we will clear the value in the trigger dictionary
                        
                        if gap > 5 * 60 * 1000 {
                            t.removeValue(forKey: id)
                            for i in CLProximity.allValues {
                                switch i{
                                case .unknown:
                                    // unknown
                                    unknownTrigger = t
                                case .immediate:
                                    // immediate
                                    immediateTrigger = t
                                case .near:
                                    // near
                                    nearTrigger = t
                                case .far:
                                    // far
                                    farTrigger = t
                                }
                            }
                        }
                    }
                }
            }
            
            
            for i in CLProximity.allValues {
                switch i {
                case .unknown:
                    // unknown
                    trigger = unknownTrigger
                    refresh(trigger: trigger)
                case .immediate:
                    // immediate
                    trigger = immediateTrigger
                    refresh(trigger: trigger)
                case .near:
                    // near
                    trigger = nearTrigger
                    refresh(trigger: trigger)
                case .far:
                    // far
                    trigger = farTrigger
                    refresh(trigger: trigger)
                }
            }
        }
    }
}
