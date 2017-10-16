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
    var immediateBeacons : [String] = []
    var nearBeacons : [String] = []
    var farBeacons : [String] = []
    var unknownBeacons : [String] = []
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
        super.init()

        self.clLocationManager.delegate = self
        self.clLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.clLocationManager.requestAlwaysAuthorization()
    }
    
    func initialize(){
        superGetBeacons(completion: {
            (_ beacons) in
            if !beacons.isEmpty{
                let uuid = self.getUuid(beacons: beacons)
                var i = 0
                for region in uuid {
                    self.startRanging(forUuid: region, identifier: "Region " + String(i))
                    i += 1
                }
                self.startBeaconsProximityEvent(forCLProximity: .immediate)
                self.startBeaconsProximityEvent(forCLProximity: .near)
            }
            print("Context Manager is initialized.")
            

        })
    }
    
    private func getUuid(beacons: [IBeaconDevice]) -> [UUID]{
        var uuids : [UUID] = []
        for beacon in beacons{
            let uuid = beacon.proximityUUID
            if !uuids.contains(UUID.init(uuidString: uuid!)!){
                uuids.append(UUID.init(uuidString: uuid!)!)
            }
        }
        return uuids
    }
    
    private func superGetBeacons(completion: @escaping ((_ beacons: [IBeaconDevice]) -> Void)){
        let userId = alpsManager.apiKey
        let _ = Alps.UserAPI.getDevices(userId: userId, completion: {(_ devices, error)in
            if error == nil {
                completion(devices as! [IBeaconDevice])
            }
        })
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
//            do {
                //try self.onLocationUpdateClosure?(locations.last!)
                //try alpsManager.updateLocation(latitude: coord.coordinate.latitude, longitude: coord.coordinate.longitude,
            self.onLocationUpdateClosure?(locations.last!)
            alpsManager.updateLocation(latitude: coord.coordinate.latitude, longitude: coord.coordinate.longitude,
                                             altitude: coord.altitude, horizontalAccuracy: coord.horizontalAccuracy,
                                             verticalAccuracy: coord.verticalAccuracy) {
                    (_ location) in
//                    NSLog("updating location to: \(coord.coordinate.latitude), \(coord.coordinate.longitude), \(coord.altitude)")
                }
//            } catch {
//                // Allow to update location even when there is no device / user created
//            }
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
    private func startRanging(forUuid : UUID, identifier : String){
        let ourCLBeaconRegion = CLBeaconRegion.init(proximityUUID: forUuid, identifier: identifier)
        clLocationManager.startRangingBeacons(in: ourCLBeaconRegion)
    }
    
    private func stopRanging(forUuid : UUID){
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
//            do {
//                // If the developer needs the closest beacon or the detected beacons, he/she can access it with these 2 fields.
//                try self.closestBeaconClosure?(closestBeacon)
                    self.closestBeaconClosure?(closestBeacon)
                    self.detectedBeaconsClosure?(beacons)
//            } catch {
//                // just to catch
//            }
        }
        
        // Proximity Events related
        parseBeaconsByProximity(beacons)
        if proximityTrigger.isEmpty {
            // No proximity event are triggering yet since proximityTrigger array is empty
        } else {
            for pt in proximityTrigger{
                switch pt {
                case .immediate:
                    triggerBeaconsProximityEvent(forCLProximity: pt)
                    break
                case .near:
                    triggerBeaconsProximityEvent(forCLProximity: pt)
                    break
                case .far:
                    triggerBeaconsProximityEvent(forCLProximity: pt)
                    break
                case .unknown:
                    triggerBeaconsProximityEvent(forCLProximity: pt)
                    break
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(error)
        seenError = true
    }
    
    func getClosestOnBeaconUpdate(completion: @escaping (_ beacon: CLBeacon) -> Void){
        closestBeaconClosure = completion
    }
    
    func getAllOnBeaconUpdate(completion: @escaping (_ beacons: [CLBeacon]) -> Void){
        detectedBeaconsClosure = completion
    }
    
    private func parseBeaconsByProximity(_ beacons: [CLBeacon]){
        var ourBeacon : IBeaconDevice?
        for beacon in beacons {
            let b = syncBeacon(beacon: beacon)
            if b.isEmpty != true {
                ourBeacon = b[0]
            }
            if let deviceId = ourBeacon?.id{
                switch beacon.proximity {
                case .immediate:
                    if immediateBeacons.contains(deviceId){
                        // If beacon is already detected no need to do anything
                    } else {
                        if nearBeacons.contains(deviceId) {
                            if let index = nearBeacons.index(of: deviceId) {
                                nearBeacons.remove(at: index)
                            }
                        }
                        if farBeacons.contains(deviceId) {
                            if let index = farBeacons.index(of: deviceId) {
                                farBeacons.remove(at: index)
                            }
                        }
                        if unknownBeacons.contains(deviceId) {
                            if let index = unknownBeacons.index(of: deviceId) {
                                unknownBeacons.remove(at: index)
                            }
                        }
                        immediateBeacons.append(deviceId)
                    }
                    break
                case .near:
                    if nearBeacons.contains(deviceId){
                        // If beacon is already detected no need to do anything
                    }else {
                        if immediateBeacons.contains(deviceId) {
                            if let index = immediateBeacons.index(of: deviceId) {
                                immediateBeacons.remove(at: index)
                            }
                        }
                        if farBeacons.contains(deviceId) {
                            if let index = farBeacons.index(of: deviceId) {
                                farBeacons.remove(at: index)
                            }
                        }
                        if unknownBeacons.contains(deviceId) {
                            if let index = unknownBeacons.index(of: deviceId) {
                                unknownBeacons.remove(at: index)
                            }
                        }
                        nearBeacons.append(deviceId)
                    }
                    break
                case .far:
                    if farBeacons.contains(deviceId){
                        // If beacon is already detected no need to do anything
                    }else {
                        if immediateBeacons.contains(deviceId) {
                            if let index = immediateBeacons.index(of: deviceId) {
                                immediateBeacons.remove(at: index)
                            }
                        }
                        if nearBeacons.contains(deviceId) {
                            if let index = nearBeacons.index(of: deviceId) {
                                nearBeacons.remove(at: index)
                            }
                        }
                        if unknownBeacons.contains(deviceId) {
                            if let index = unknownBeacons.index(of: deviceId) {
                                unknownBeacons.remove(at: index)
                            }
                        }
                        farBeacons.append(deviceId)
                    }
                    break
                case .unknown:
                    if unknownBeacons.contains(deviceId){
                        // If beacon is already detected no need to do anything
                    }else{
                        if immediateBeacons.contains(deviceId) {
                            if let index = immediateBeacons.index(of: deviceId) {
                                immediateBeacons.remove(at: index)
                            }
                        }
                        if nearBeacons.contains(deviceId) {
                            if let index = nearBeacons.index(of: deviceId) {
                                nearBeacons.remove(at: index)
                            }
                        }
                        if farBeacons.contains(deviceId) {
                            if let index = farBeacons.index(of: deviceId) {
                                farBeacons.remove(at: index)
                            }
                        }
                        unknownBeacons.append(deviceId)
                    }
                    break
                }
            }
        }
    }
    
    private func syncBeacon(beacon: CLBeacon) -> [IBeaconDevice] {
        var b : [IBeaconDevice] = self.alpsManager.beacons
        b = self.alpsManager.beacons.filter{
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
    
    private func triggerProximityEvent(userId: String, deviceId: String, proximityEvent: ProximityEvent, completion: @escaping (_ proximityEvent: ProximityEvent?) -> Void) {
        let userCompletion = completion
        let _ = Alps.DeviceAPI.triggerProximityEvents(userId: userId, deviceId: deviceId, proximityEvent: proximityEvent) {
            (proximityEvent, error) -> Void in
            userCompletion(proximityEvent)
        }
    }
    
    private func startBeaconsProximityEvent(forCLProximity: CLProximity) {
        proximityTrigger.insert(forCLProximity)
        // To change the TIMERS ! https://developer.apple.com/library/content/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/Timers.html Reducing overhead
//        switch forCLProximity {
//        case .immediate:
//            immediateTimer = Timer.scheduledTimer(timeInterval: 2, target: ContextManager.self , selector: #selector(ContextManager.refreshTriggers), userInfo: nil, repeats: true)
//            break
//        case .near:
//            nearTimer = Timer.scheduledTimer(timeInterval: 2, target: ContextManager.self , selector: #selector(ContextManager.refreshTriggers), userInfo: nil, repeats: true)
//            break
//        case .far:
//            farTimer = Timer.scheduledTimer(timeInterval: 300, target: ContextManager.self , selector: #selector(ContextManager.refreshTriggers), userInfo: nil, repeats: true)
//            break
//        case .unknown:
//            unknownTimer = Timer.scheduledTimer(timeInterval: 300, target: ContextManager.self , selector: #selector(ContextManager.refreshTriggers), userInfo: nil, repeats: true)
//            break
//        }
    }
    
    private func stopBeaconsProximityEvent(forCLProximity: CLProximity) {
        proximityTrigger.remove(forCLProximity)
//        switch forCLProximity {
//        case .immediate:
//            immediateTimer?.invalidate()
//            break
//        case .near:
//            nearTimer?.invalidate()
//            break
//        case .far:
//            farTimer?.invalidate()
//            break
//        case .unknown:
//            unknownTimer?.invalidate()
//            break
//        }
    }
    
    private func triggerBeaconsProximityEvent(forCLProximity: CLProximity) {
        var beacons : [String] = []
        var trigger : [String:ProximityEvent] = [:]
        var distance : Double = 0.0
        // Setting parameters upon the case
        switch forCLProximity{
        case .immediate:
            beacons = immediateBeacons
            trigger = ContextManager.immediateTrigger
            distance = 0.5
            break
        case .near:
            beacons = nearBeacons
            trigger = ContextManager.nearTrigger
            distance = 3.0
            break
        case .far:
            beacons = farBeacons
            trigger = ContextManager.farTrigger
            distance = 50.0
            break
        case .unknown:
            beacons = unknownBeacons
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
    private class func refreshTriggers() {
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
                        for proximity in CLProximity.allValues {
                            switch proximity{
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
                            }
                        }
                    }
                }
            }
        }
        
        for proximity in CLProximity.allValues {
            switch proximity {
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
            }
        }
    }

}
