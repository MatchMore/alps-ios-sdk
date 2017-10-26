//
//  ProximityHandler.swift
//  AlpsSDK
//
//  Created by Wen on 26.10.17.
//  Copyright © 2017 Alps. All rights reserved.
//

import Foundation
import CoreLocation
import Alps

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
    var refreshTimer : Int = 60 * 1000 // timer is in milliseconds
    
    init(contextManager: ContextManager) {
        self.contextManager = contextManager
    }
    
    // Parsing beacons proximity relatively to the device that detect them
    func parseBeaconsByProximity(_ beacons: [CLBeacon]){
        var ourBeacon : IBeaconDevice?
        for beacon in beacons {
            let b = syncBeacon(beacon: beacon)
            if b.isEmpty != true {
                ourBeacon = b[0]
            }
            if let deviceId = ourBeacon?.id{
                removeDuplicate(clBeacon: beacon, deviceId : deviceId)
            }
        }
    }
    
    // Launch a proximity event
    func triggerBeaconsProximityEvent() {
        for clProximity in CLProximity.allValues{
            var (beacons, trigger, distance) = setUpTriggerBeaconsProximityEvent(forCLProximity: clProximity)
            for id in beacons{
                // Check if a proximity event already exist
                if trigger[id] == nil {
                    // Send the proximity event
                    let proximityEvent = ProximityEvent.init(deviceId: id, distance: distance)
                    let userId = self.contextManager.alpsManager.alpsUser?.user.id
                    if let deviceId = self.contextManager.alpsManager.alpsDevice?.device.id {
                        sendProximityEvent(userId: userId!, deviceId: deviceId, proximityEvent: proximityEvent) {
                            (_ proximityEvent) in
                            if let pe = proximityEvent{
                                self.addProximityEvent(id: id, proximityEvent: pe, clProximity: clProximity)
                            }
                        }
                    }
                } else {
                    //this id is already triggered and might need to be refresh -> refreshTriggers()
                }
            }
        }
    }
    
    // Re-launch a proximity event depending on refreshTimer (Default : 60 seconds)
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
    
    // Remove the previous sent Proximity Event that was higher than a fixed time (Default: 5 minutes).
    @objc
    private func cleanTriggers() {
        func clean(trigger: [String:ProximityEvent]) -> [String:ProximityEvent]{
            var t = trigger
            for (id, proximityEvent) in t {
                if let createdAt = proximityEvent.createdAt {
                    let now = Int64(Date().timeIntervalSince1970 * 1000)
                    let gap = now - createdAt
                    // If gap is higher than 5 minutes we will clear the value in the trigger dictionary
                    if gap > 5 * 60 * 1000 {
                        t.removeValue(forKey: id)
                    }
                }
            }
            return t
        }
        
        for clProximity in CLProximity.allValues{
            switch clProximity{
            case .unknown: ProximityHandler.unknownTrigger = clean(trigger: ProximityHandler.unknownTrigger)
            case .immediate: ProximityHandler.immediateTrigger = clean(trigger: ProximityHandler.immediateTrigger)
            case .near: ProximityHandler.nearTrigger = clean(trigger: ProximityHandler.nearTrigger)
            case .far: ProximityHandler.farTrigger = clean(trigger: ProximityHandler.farTrigger)
            }
        }
    }
    
    //MARK: Helper Function
    // List of beacons currently tracked by the application, means beacons are registered in portal
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
    
    // Keep track of none duplicity in beacon proximity array
    private func removeDuplicate(clBeacon: CLBeacon, deviceId : String) {
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
        
        // SI il ne change pas de distance il faut pas renvoyer un proximity event
        if immediateBeacons.contains(deviceId) || nearBeacons.contains(deviceId) || farBeacons.contains(deviceId) || unknownBeacons.contains(deviceId) {
            immediateBeacons = removeBeacon(deviceId : deviceId, fromArray: immediateBeacons)
            nearBeacons = removeBeacon(deviceId: deviceId, fromArray: nearBeacons)
            farBeacons = removeBeacon(deviceId: deviceId, fromArray: farBeacons)
            unknownBeacons = removeBeacon(deviceId: deviceId, fromArray: unknownBeacons)
        }
        addBeacon(clBeacon: clBeacon, deviceId: deviceId)
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
    
    private func addProximityEvent(id: String, proximityEvent: ProximityEvent, clProximity: CLProximity) {
        switch clProximity {
        case .unknown: ProximityHandler.unknownTrigger[id] = proximityEvent
        case .immediate: ProximityHandler.immediateTrigger[id] = proximityEvent
        case .near: ProximityHandler.nearTrigger[id] = proximityEvent
        case .far: ProximityHandler.farTrigger[id] = proximityEvent
        }
    }

    // MARK: API CALLS
    // Send the proximity event to the cloud service
    private func sendProximityEvent(userId: String, deviceId: String, proximityEvent: ProximityEvent, completion: @escaping (_ proximityEvent: ProximityEvent?) -> Void) {
        let userCompletion = completion
        let _ = Alps.DeviceAPI.triggerProximityEvents(userId: userId, deviceId: deviceId, proximityEvent: proximityEvent) {
            (proximityEvent, error) -> Void in
            userCompletion(proximityEvent)
        }
    }
}
