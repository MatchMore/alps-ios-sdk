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
    var seenError = false
    var locationFixAchieved = false

    let clLocationManager: CLLocationManager

    var onLocationUpdateClosure: ((_ location: CLLocation) -> Void)?
    
    // Beacons
    // Triggered proximity event map
    var refreshTimer : Int = 60 * 1000 // timer is in milliseconds
    var proximityTrigger = Set<CLProximity>()
    // [Is the id of the IBeaconDevice registered in the core : The returned ProximityEvent will be stored ]
    static var immediateTrigger : [String:ProximityEvent] = [:]
    static var nearTrigger : [String:ProximityEvent] = [:]
    static var farTrigger : [String:ProximityEvent] = [:]
    static var unknownTrigger : [String:ProximityEvent] = [:]
    private(set) var proximityHandler : ProximityHandler!
    var immediateTimer : Timer?
    var nearTimer : Timer?
    var farTimer : Timer?
    var unknownTimer : Timer?
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
        self.proximityHandler = ProximityHandler(contextManager: self)
        super.init()

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
        } else {
            // don't do anything
        }
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
        proximityTrigger.insert(forCLProximity)
    }
    
    public func stopBeaconsProximityEvent(forCLProximity: CLProximity) {
        proximityTrigger.remove(forCLProximity)
    }
    
    private func triggerBeaconsProximityEvent(forCLProximity: CLProximity) {
        var beacons : [String] = []
        var trigger : [String:ProximityEvent] = [:]
        var distance : Double = 0.0
        // Setting parameters upon the case
        switch forCLProximity{
        case .immediate:
            beacons = proximityHandler.immediateBeacons
            trigger = ContextManager.immediateTrigger
            distance = 0.5
            break
        case .near:
            beacons = proximityHandler.nearBeacons
            trigger = ContextManager.nearTrigger
            distance = 3.0
            break
        case .far:
            beacons = proximityHandler.farBeacons
            trigger = ContextManager.farTrigger
            distance = 50.0
            break
        case .unknown:
            beacons = proximityHandler.unknownBeacons
            trigger = ContextManager.unknownTrigger
            distance = 200.0
            break
        }
        for id in beacons{
            // Check if a proximity event already exist
            if trigger[id] == nil {
                // Send the proximity event
                let proximityEvent = ProximityEvent.init(deviceId: id, distance: distance)
                let userId = self.alpsManager.alpsUser?.user.id
                let deviceId = self.alpsManager.alpsDevice?.device.id
                triggerProximityEvent(userId: userId!, deviceId: deviceId!, proximityEvent: proximityEvent) {
                    (_ proximityEvent) in
                    trigger[id] = proximityEvent
                    switch forCLProximity{
                    case .immediate:
                        ContextManager.immediateTrigger = trigger
                        break
                    case .near:
                        ContextManager.nearTrigger = trigger
                        break
                    case .far:
                        ContextManager.farTrigger = trigger
                        break
                    case .unknown:
                        ContextManager.unknownTrigger = trigger
                        break
                    }
                }
            } else {
                // Should be done in another function refreshing()
                // Check if the existed proximity event needs a refresh on a based timer
                let proximityEvent = trigger[id]
                // Represents  the UNIX current time in milliseconds
                let now = Int64(Date().timeIntervalSince1970 * 1000)
                if let proximityEventCreatedAt = proximityEvent?.createdAt{
                    let gap = now - proximityEventCreatedAt
                    let truncatedGap = Int(truncatingBitPattern: gap)
                    if truncatedGap > refreshTimer {
                        // Send the refreshing proximity event based on the timer
                        let newProximityEvent = ProximityEvent.init(deviceId: id, distance: distance)
                        let userId = self.alpsManager.alpsUser?.user.id
                        let deviceId = self.alpsManager.alpsDevice?.device.id
                        triggerProximityEvent(userId: userId!, deviceId: deviceId!, proximityEvent: newProximityEvent) {
                            (_ proximityEvent) in
                            trigger[id] = proximityEvent
                            switch forCLProximity{
                            case .immediate:
                                ContextManager.immediateTrigger = trigger
                                break
                            case .near:
                                ContextManager.nearTrigger = trigger
                                break
                            case .far:
                                ContextManager.farTrigger = trigger
                                break
                            case .unknown:
                                ContextManager.unknownTrigger = trigger
                                break
                            }
                        }
                    }else{
                        // Do something when it doesn't need to be refreshed
                    }
                } else {
                    print("ERROR : CreatedAt in a proximity event is nil.")
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
                                break
                            case .immediate:
                                // immediate
                                immediateTrigger = t
                                break
                            case .near:
                                // near
                                nearTrigger = t
                                break
                            case .far:
                                // far
                                farTrigger = t
                                break
                            default:
                                break
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
                break
            case .immediate:
                // immediate
                trigger = immediateTrigger
                refresh(trigger: trigger)
                break
            case .near:
                // near
                trigger = nearTrigger
                refresh(trigger: trigger)
                break
            case .far:
                // far
                trigger = farTrigger
                refresh(trigger: trigger)
                break
            default:
                print("This shouldn't be printed, we are in default case.")
                break
            }
        }
    }
    
    class ProximityHandler {
        
        var contextManager : ContextManager!
        var immediateTrigger : [String:ProximityEvent] = [:]
        var nearTrigger : [String:ProximityEvent] = [:]
        var farTrigger : [String:ProximityEvent] = [:]
        var unknownTrigger : [String:ProximityEvent] = [:]
        var immediateBeacons : [String] = []
        var nearBeacons : [String] = []
        var farBeacons : [String] = []
        var unknownBeacons : [String] = []
        
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
                if let index = beaconsId.index(of: deviceId){
                    beaconsId.remove(at: index)
                }
                return beaconsId
            }
            var detectedBeaconChange = false
            if immediateBeacons.contains(deviceId) || nearBeacons.contains(deviceId) || farBeacons.contains(deviceId) || unknownBeacons.contains(deviceId){
                if immediateBeacons.contains(deviceId){
                    immediateBeacons = removeBeacon(deviceId : deviceId, fromArray: immediateBeacons)
                }
                if nearBeacons.contains(deviceId) {
                    nearBeacons = removeBeacon(deviceId: deviceId, fromArray: nearBeacons)
                }
                if farBeacons.contains(deviceId) {
                    farBeacons = removeBeacon(deviceId: deviceId, fromArray: farBeacons)
                }
                if unknownBeacons.contains(deviceId) {
                    unknownBeacons = removeBeacon(deviceId: deviceId, fromArray: unknownBeacons)
                }
                switch clBeacon.proximity {
                case .unknown: unknownBeacons.append(deviceId)
                case .immediate: immediateBeacons.append(deviceId)
                case .near: nearBeacons.append(deviceId)
                case .far: farBeacons.append(deviceId)
                }
                detectedBeaconChange = true
            }
            return detectedBeaconChange
        }
        
        private func setUpTriggerBeaconsProximityEvent(forCLProximity: CLProximity) -> ([String], [String: ProximityEvent], Double) {
            var beacons : [String]
            var trigger : [String:ProximityEvent]
            var distance : Double
            switch forCLProximity {
            case .immediate:
                beacons = immediateBeacons
                trigger = immediateTrigger
                distance = 0.5
            case .near:
                beacons = nearBeacons
                trigger = nearTrigger
                distance = 3.0
            case .far:
                beacons = farBeacons
                trigger = farTrigger
                distance = 50.0
            case .unknown:
                beacons = unknownBeacons
                trigger = unknownTrigger
                distance = 200.0
            }
            return (beacons, trigger, distance)
        }
        
        private func setTrigger(forCLProximity: CLProximity, trigger : [String:ProximityEvent]) {
            switch forCLProximity{
            case .immediate:
                ContextManager.immediateTrigger = trigger
                break
            case .near:
                ContextManager.nearTrigger = trigger
                break
            case .far:
                ContextManager.farTrigger = trigger
                break
            case .unknown:
                ContextManager.unknownTrigger = trigger
                break
            }
        }
        
        private func sendProximityEvent(userId: String, deviceId: String, proximityEvent: ProximityEvent, completion: @escaping (_ proximityEvent: ProximityEvent?) -> Void) {
            let userCompletion = completion
            let _ = Alps.DeviceAPI.triggerProximityEvents(userId: userId, deviceId: deviceId, proximityEvent: proximityEvent) {
                (proximityEvent, error) -> Void in
                userCompletion(proximityEvent)
            }
        }
        
        private func addProximityEvent(forTrigger: [String:ProximityEvent], id: String, proximityEvent: ProximityEvent) -> [String:ProximityEvent]{
            var trigger : [String : ProximityEvent] = forTrigger
            trigger[id] = proximityEvent
            return trigger
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
                            switch clProximity {
                            case .unknown: self.unknownTrigger = self.addProximityEvent(forTrigger: self.unknownTrigger, id: id, proximityEvent: proximityEvent!)
                            case .immediate: self.immediateTrigger = self.addProximityEvent(forTrigger: self.immediateTrigger, id: id, proximityEvent: proximityEvent!)
                            case .near: self.nearTrigger = self.addProximityEvent(forTrigger: self.nearTrigger, id: id, proximityEvent: proximityEvent!)
                            case .far: self.farTrigger = self.addProximityEvent(forTrigger: self.farTrigger, id: id, proximityEvent: proximityEvent!)
                            }
                        }
                    }
                }
            }
        }

    
        private func refreshTriggers(forCLProximity: CLProximity) {
            // Check if the existed proximity event needs a refresh on a based timer
            let proximityEvent = trigger[id]
            // Represents  the UNIX current time in milliseconds
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            if let proximityEventCreatedAt = proximityEvent?.createdAt{
                let gap = now - proximityEventCreatedAt
                let truncatedGap = Int(truncatingBitPattern: gap)
                if truncatedGap > refreshTimer {
                    // Send the refreshing proximity event based on the timer
                    let newProximityEvent = ProximityEvent.init(deviceId: id, distance: distance)
                    let userId = self.alpsManager.alpsUser?.user.id
                    let deviceId = self.alpsManager.alpsDevice?.device.id
                    triggerProximityEvent(userId: userId!, deviceId: deviceId!, proximityEvent: newProximityEvent) {
                        (_ proximityEvent) in
                        trigger[id] = proximityEvent
                    }
                }else{
                    // Do something when it doesn't need to be refreshed
                }
            }
        }
    }
}
