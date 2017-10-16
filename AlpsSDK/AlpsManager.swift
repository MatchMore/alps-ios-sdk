/**
 * AlpsManager
 */

import Foundation
import CoreLocation
import Alps

enum AlpsManagerError: Error {
    case userNotIntialized
    case deviceNotInitialized
}

open class AlpsManager: AlpsSDK {
    let defaultHeaders = [
      // FIXME: pass both keys on AlpsManager creation
      "api-key": "833ec460-c09d-11e6-9bb0-cfb02086c30d",
      "Content-Type": "application/json; charset=UTF-8",
      "Accept": "application/json",
      "user-agent": "\(UIDevice().systemName) \(UIDevice().systemVersion)",
    ]

    let headers: [String: String]

    // XXX: this has to come from a configuration
    let alpsEndpoint = "https://api.matchmore.io/v4"
    // let alpsEndpoint = "http://localhost:9000"
    
    // Put setup code here. This method is called before the invocation of each test method in t
    let apiKey: String
    var contextManager: ContextManager? = nil
    var matchMonitor: MatchMonitor? = nil
    var notificationManager: NotificationManager? = nil

    // FIXME: add the world id when it's there
    // var world: World
    var users: [User] = []
    var alpsUser: AlpsUser?
    var devices: [Device] = []
    var alpsDevice: AlpsDevice?
    var locations: [String: Location] = [:]
    var publications: [String: [Publication]] = [:]
    var subscriptions: [String: [Subscription]] = [:]
//    var publications: [Publication] = []
//    var subscriptions: [Subscription] = []
    
    // DEVELOP: Beacons
    // depending on the case beacons will have different class in his array
    // Variant 1 is enum => Device with DeviceType
    // Variant 2 is sub-classes => BeaconDevice
    // Variant 3 is protocol => BeaconDevice
    var beacons: [IBeaconDevice] = []
    
    public convenience init(apiKey: String) {
        self.init(apiKey: apiKey, clLocationManager: CLLocationManager())
    }

    public init(apiKey: String, clLocationManager: CLLocationManager) {
        self.apiKey = apiKey
        self.headers = defaultHeaders.merged(with: ["api-key": apiKey])
        self.contextManager = ContextManager(alpsManager: self, locationManager: clLocationManager)
        self.matchMonitor = MatchMonitor(alpsManager: self)
        self.notificationManager = NotificationManager(alpsManager: self)

        AlpsAPI.basePath = alpsEndpoint
        AlpsAPI.customHeaders = headers
        
        initialize()
    }
    
    private func initialize(){
        // Setup to initialize for SDK
        self.contextManager?.initialize()
        self.notificationManager?.initialize()
    }

    // Create Alps entities
    public func createUser(_ userName: String, completion: @escaping (_ user: User?) -> Void) {
        let userCompletion = completion
        let user = User.init(name: userName)
        let _ = Alps.UsersAPI.createUser(user: user) {
            (user, error) -> Void in
            if let u = user {
                self.users.append(u)
                self.alpsUser = AlpsUser(manager: self, user: self.users[0])
            }
            userCompletion(user)
        }
    }

    // Deprecated v.0.0.3
//    public func createDevice(name: String, platform: String, deviceToken: String,
//                             latitude: Double, longitude: Double, altitude: Double,
//                             horizontalAccuracy: Double, verticalAccuracy: Double,
//                             completion: @escaping (_ device: Device?) -> Void) {
//        let userCompletion = completion
//        if let u = alpsUser {
//            let _ = Alps.UserAPI.createDevice(userId: u.user.userId!, name: name, platform: platform,
//                                              deviceToken: deviceToken, latitude: latitude, longitude: longitude,
//                                              altitude: altitude, horizontalAccuracy: horizontalAccuracy,
//                                              verticalAccuracy: verticalAccuracy) {
//                (device, error) -> Void in
//                if let d = device {
//                    self.devices.append(d)
//                    self.alpsDevice = AlpsDevice(manager: self, user: u.user, device: self.devices[0])
//                }
//                userCompletion(device)
//            }
//        } else {
//            // XXX: error handling using exceptions?
//            print("Alps user hasn't been initialized yet!")
//            // throw AlpsManagerError.userNotIntialized
//        }
//    }
    
    // Create Main device, this function replace createDevice in v 0.0.3
    public func createMobileDevice(name: String, platform: String, deviceToken: String,
                             latitude: Double, longitude: Double, altitude: Double,
                             horizontalAccuracy: Double, verticalAccuracy: Double,
                             completion: @escaping (_ device: MobileDevice?) -> Void) {
        let userCompletion = completion
        if let u = alpsUser {
            let location = Location.init(latitude: latitude, longitude: longitude, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy)
            let mobileDevice = MobileDevice.init(name: name, platform: platform, deviceToken: deviceToken, location: location)
            if let userId = u.user.id {
                let _ = Alps.UserAPI.createDevice(userId: userId, device: mobileDevice) {
                                                    (mobileDevice, error) -> Void in
                                                if mobileDevice is MobileDevice{
                                                    if let d = mobileDevice as? MobileDevice {
                                                        self.devices.append(d)
                                                        self.alpsDevice = AlpsDevice(manager: self, user: u.user, device: self.devices[0])
                                                        self.publications[d.id!] = [Publication]()
                                                        self.subscriptions[d.id!] = [Subscription]()
                                                    }
                                                    userCompletion(mobileDevice as? MobileDevice)
                    }
                }
            } else {
                print("Error forcing userId is nil.")
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }
    }
    
    // Create a pinned Device, stays at the same location
    public func createPinDevice(name: String, latitude: Double, longitude: Double, altitude: Double,
                         horizontalAccuracy: Double, verticalAccuracy: Double,
                         completion: @escaping (_ device: PinDevice?) -> Void) {
        let userCompletion = completion
        if let u = alpsUser {
            let location = Location.init(latitude: latitude, longitude: longitude, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy)
            let pinDevice = PinDevice.init(name: name, location: location)
            if let userId = u.user.id {
                let _ = Alps.UserAPI.createDevice(userId: userId, device: pinDevice) {
                    (pinDevice, error) -> Void in
                    if pinDevice is PinDevice{
                        if let d = pinDevice as? PinDevice {
                            self.devices.append(d)
                            self.publications[d.id!] = [Publication]()
                            self.subscriptions[d.id!] = [Subscription]()
                        }
                        userCompletion(pinDevice as? PinDevice)
                    }
                }
            } else {
                print("Error forcing userId is nil.")
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }
    }
    
    // Create a BLE iBeacon Device
    public func createIBeaconDevice(name: String, proximityUUID: String, major: NSNumber, minor: NSNumber,
                                    completion: @escaping (_ device: IBeaconDevice?) -> Void) {
        let userCompletion = completion
        if let u = alpsUser {
            let iBeaconDevice = IBeaconDevice.init(name: name, proximityUUID: proximityUUID, major: major, minor: minor)
            if let userId = u.user.id {
                let _ = Alps.UserAPI.createDevice(userId: userId, device: iBeaconDevice) {
                    (iBeaconDevice, error) -> Void in
                    if iBeaconDevice is IBeaconDevice{
                        if let d = iBeaconDevice as? IBeaconDevice {
                            self.devices.append(d)
                            self.publications[d.id!] = [Publication]()
                            self.subscriptions[d.id!] = [Subscription]()
                        }
                        userCompletion(iBeaconDevice as? IBeaconDevice)
                    }
                }
            } else {
                print("Error forcing userId is nil.")
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }
    }
    
    // create a publication for the main device
    public func createPublication(topic: String, range: Double, duration: Double, properties: [String: String],
                                  completion: @escaping (_ publication: Publication?) -> Void) {
        let userCompletion = completion
        
        if let u = alpsUser, let d = alpsDevice {
            if let userId = u.user.id, let deviceId = d.device.id{
                let publication = Publication.init(deviceId: deviceId, topic: topic, range: range, duration: duration, properties: properties)
                let _ = Alps.DeviceAPI.createPublication(userId: userId, deviceId: deviceId,
                                                         publication: publication) {
                                                            (publication, error) -> Void in
                                                            
                                                            if let p = publication {
                                                                self.publications[deviceId]?.append(p)
//                                                                self.publications.append(p)
                                                            }
                                                            
                                                            userCompletion(publication)
                }
            } else {
                print("Error forcing userId or/and deviceId is nil.")
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user and/or device hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }
    }
    
    // Create a publication for the given userId and given deviceId
    public func createPublication(userId: String, deviceId: String, topic: String, range: Double, duration: Double, properties: [String:String],
                                  completion: @escaping (_ publication: Publication?) -> Void) {
        let userCompletion = completion
        let publication = Publication.init(deviceId: deviceId, topic: topic, range: range, duration: duration, properties: properties)
        let _ = Alps.DeviceAPI.createPublication(userId: userId, deviceId: deviceId,
                                                 publication: publication) {
            (publication, error) -> Void in

                                                    if let p = publication {
                                                        self.publications[deviceId]?.append(p)
//                                                        self.publications.append(p)
                                                    }
            userCompletion(publication)
        }
    }

    // Create subscription for main device
    public func createSubscription(topic: String, selector: String, range: Double, duration: Double,
                                   completion: @escaping (_ subscription: Subscription?) -> Void) {
        let userCompletion = completion

        if let u = alpsUser, let d = alpsDevice {
            if let userId = u.user.id, let deviceId = d.device.id{
                let subscription = Subscription.init(deviceId: deviceId, topic: topic, range: range, duration: duration, selector: selector)
                let _ = Alps.DeviceAPI.createSubscription(userId: userId, deviceId: deviceId,
                                                          subscription: subscription) {
                    (subscription, error) -> Void in

                    if let p = subscription {
                        self.subscriptions[deviceId]?.append(p)
//                        self.subscriptions.append(p)
                    }

                    userCompletion(subscription)
                }
            }else{
                print("Error forcing userId or/and deviceId is nil.")
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user and/or device hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }
    }
    
    // Create a subscription for the given userId and given deviceId
    public func createSubscription(userId: String, deviceId: String, topic: String, selector: String, range: Double, duration: Double,
                                   completion: @escaping (_ subscription: Subscription?) -> Void) {
        let userCompletion = completion
        let subscription = Subscription.init(deviceId: deviceId, topic: topic, range: range, duration: duration, selector: selector)
        let _ = Alps.DeviceAPI.createSubscription(userId: userId, deviceId: deviceId,
                                                  subscription: subscription) {
                                                    (subscription, error) -> Void in
                                                    if let p = subscription{
                                                        self.subscriptions[deviceId]?.append(p)
//                                                        self.subscriptions.append(p)
                                                    }
                                                    userCompletion(subscription)
        }
    }

    public func updateLocation(userId:String, deviceId: String, latitude: Double, longitude: Double, altitude: Double,
                               horizontalAccuracy: Double, verticalAccuracy: Double,
                               completion: @escaping (_ location: Location?) -> Void) {
        let userCompletion = completion
        let location = Location.init(latitude: latitude, longitude: longitude, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy)
        let _ = Alps.DeviceAPI.createLocation(userId: userId, deviceId: deviceId,
                                              location: location) {
            (location, error) -> Void in
            userCompletion(location)
        }
    }

    // Update main device location
    public func updateLocation(latitude: Double, longitude: Double, altitude: Double,
                               horizontalAccuracy: Double, verticalAccuracy: Double,
                               completion: @escaping (_ location: Location?) -> Void) {
        let userCompletion = completion

        if let u = alpsUser, let d = alpsDevice {
            let location = Location.init(latitude: latitude, longitude: longitude, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy)
            if let userId = u.user.id, let deviceId = d.device.id{
                let _ = Alps.DeviceAPI.createLocation(userId: userId, deviceId: deviceId,
                                                      location: location) {
                    (location, error) -> Void in

                        if let l = location {
                            self.locations[deviceId] = l
                        }
                        userCompletion(location)
                }
            } else {
                print("Alps user and/or device has no id !")
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user and/or device hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }

    }

    public func getAllMatches(userId: String, deviceId:String, completion: @escaping (_ matches: Matches) -> Void) {
        let userCompletion = completion

        let _ = Alps.DeviceAPI.getMatches(userId: userId, deviceId: deviceId) {
            (matches, error) -> Void in

            if let ms = matches {
                userCompletion(ms)
            }
        }
    }

    // Get all matches for main device
    public func getAllMatches(completion: @escaping (_ matches: Matches) -> Void) {
        let userCompletion = completion

        if let u = alpsUser, let d = alpsDevice {
            if let userId = u.user.id, let deviceId = d.device.id {
                let _ = Alps.DeviceAPI.getMatches(userId: userId, deviceId: deviceId) {
                    (matches, error) -> Void in

                    if let ms = matches {
                        // self.matches.append(ms)
                        userCompletion(ms)
                    }
                }
            } else {
                print("Error forcing userId or/and deviceId is nil.")
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user and/or device hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }

    }

    // register match handlers
    public func onMatch(completion: @escaping (_ match: Match) -> Void) {
        if let mm = matchMonitor {
            mm.onMatch(completion: completion)
        }
    }



    public func getUser(_ userId: String, completion: @escaping (_ user: User) -> Void) {
        let _ = Alps.UserAPI.getUser(userId: userId) {
            (user, error) -> Void in

            if let u = user {
                completion(u[0])
            }else {
                // XXX: error handling using exceptions?
                print("Alps.user doesn't exist!")
                // throw Alps.anagerError.userNotIntialized
            }
        }
    }

    public func getDevice(_ deviceId: String, completion: @escaping (_ device: Device) -> Void) {

        if let u = alpsUser, let d = alpsDevice {
            if let userId = u.user.id {
                let _ = Alps.UserAPI.getDevice(userId: userId, deviceId: deviceId) {
                    (device, error) -> Void in
                    if let d = device{
                        completion(d)
                    }
                }
            }
        } else {
            print("Error forcing userId or/and deviceId is nil.")
        }
    }

    // Deprecated for dynamic getMainDevice()
//    public func getDevice(completion: @escaping (_ device: Device) -> Void)  {
//        if let u = alpsUser, let d = alpsDevice {
//            if let userId = u.user.id, let deviceId = d.device.id {
//                let _ = Alps.UserAPI.getDevice(userId: userId, deviceId: deviceId) {
//                    (device, error) -> Void in
//                    
//                    if let d = device {
//                        completion(d)
//                    }
//                }
//            }
//        } else {
//            print("Error forcing userId or/and deviceId is nil.")
//        }
//    }

    public func getPublication(_ userId:String, deviceId:String, publicationId: String, completion: @escaping (_ publication: Publication) -> Void) {
        let _ = Alps.PublicationAPI.getPublication(userId: userId, deviceId: deviceId, publicationId: publicationId) {
            (publication, error) -> Void in
            if let p = publication {
                completion(p)
            }else {
                print("This publication doesn't exist!")
            }
        }
    }

    public func deletePublication(_ userId:String, deviceId:String, publicationId: String, completion: @escaping () -> Void) {
        let _ = Alps.PublicationAPI.deletePublication(userId: userId, deviceId: deviceId, publicationId: publicationId) {
            (error) -> Void in
            if error != nil {
                print("Impossible to delete the publication!")
            }else {
                if let index = self.publications[deviceId]?.index(where: {$0.id == publicationId}) {
                    self.publications[deviceId]?.remove(at: index)
                }
                completion()
            }
        }
    }

    public func getAllPublicationsForDevice(_ userId:String, deviceId: String, completion: @escaping (_ publications: [Publication]) -> Void) {
        let _ = Alps.PublicationAPI.getPublications(userId: userId, deviceId: deviceId) {
            (publications, error) -> Void in
            if let p = publications{
                completion(p)
            }else {
                print("Can't find publications for this device")
            }
        }
    }

    public func getSubscription(_ userId:String, deviceId: String, subscriptionId: String, completion: @escaping (_ subscription: Subscription) -> Void) {
        let _ = Alps.SubscriptionAPI.getSubscription(userId: userId, deviceId: deviceId, subscriptionId: subscriptionId) {
            (subscription, error) -> Void in
            if let s = subscription {
                completion(s)
            }else {
                print("This subscription doesn't exist!")
            }
        }
    }

    public func deleteSubscription(_ userId:String, deviceId:String, subscriptionId: String, completion: @escaping () -> Void) {
        let _ = Alps.SubscriptionAPI.deleteSubscription(userId: userId, deviceId: deviceId, subscriptionId: subscriptionId) {
            (error) -> Void in
            if let e = error {
                print("Impossible to delete the subscription!")
            }else {
                if let index = self.subscriptions[deviceId]?.index(where: {$0.id == subscriptionId}) {
                    self.subscriptions[deviceId]?.remove(at: index)
                }
                completion()
            }
        }
    }

    public func getAllSubscriptionsForDevice(_ userId:String, deviceId: String, completion: @escaping (_ subscriptions: [Subscription]) -> Void) {
        let _ = Alps.SubscriptionAPI.getSubscriptions(userId: userId, deviceId: deviceId) {
            (subscriptions, error) -> Void in
            if let s = subscriptions{
                completion(s)
            }else {
                print("Can't find subscriptions for this device")
            }
        }
    }

    public func onLocationUpdate(completion: @escaping ((_ location: CLLocation) -> Void)) {
        if let lm = contextManager {
            lm.onLocationUpdate(completion: completion)
        }
    }

    public func startMonitoringMatches() {
        if let mm = matchMonitor {
            mm.startMonitoringMatches()
        }
    }

    public func stopMonitoringMatches() {
        if let mm = matchMonitor {
            mm.stopMonitoringMatches()
        }
    }

    public func startUpdatingLocation() {
        contextManager?.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        contextManager?.stopUpdatingLocation()
    }
    
    public func getClosestOnBeaconUpdate(completion: @escaping ((_ beacon: CLBeacon) -> Void)) {
        if let cm = contextManager {
            cm.getClosestOnBeaconUpdate(completion: completion)
        }
    }
    
    public func getAllOnBeaconUpdate(completion: @escaping ((_ beacon: [CLBeacon]) -> Void)) {
        if let cm = contextManager {
            cm.getAllOnBeaconUpdate(completion: completion)
        }
    }
    
    // Automated for the moment TBD. Logic is all the beacons registered on portal are ranged.
//    public func startRangingBeacons(forUuid: UUID, identifier: String){
//        contextManager?.startRanging(forUuid: forUuid, identifier: identifier)
//    }
//    
//    public func stopRangingBeacons(forUuid: UUID){
//        contextManager?.stopRanging(forUuid: forUuid)
//    }
    
    // Automated for the moment, but it will be open to the developer if he wants to change proximity detection
//    public func startBeaconsProximityEvent(forCLProximity: CLProximity){
//        contextManager?.startBeaconsProximityEvent(forCLProximity: forCLProximity)
//    }
//    
//    public func stopBeaconsProximityEvent(forCLProximity: CLProximity){
//        contextManager?.stopBeaconsProximityEvent(forCLProximity: forCLProximity)
//    }
    
    // Default time to refresh is 60 seconds(= 60'000 milliseconds)
    public func setRefreshTimerForProximityEvent(refreshEveryInMilliseconds: Int){
        contextManager?.refreshTimer = refreshEveryInMilliseconds
    }
    
    public func getMainUser() -> User? {
        var user : User?
        if let u = alpsUser {
            user = u.user
        } else {
            print("Alps user doesn't exist!")
            //            // throw AlpsManagerError.userNotIntialized
        }
        return user
    }
    
    public func getMainDevice() -> Device? {
        var device : Device?
        if let d = alpsDevice {
            device = d.device
        } else {
            print("Alps device doesn't exist!")
            //            // throw AlpsManagerError.deviceNotIntialized
        }
        return device
    }
    
    public func getAllDevicesMainUser() -> [Device]{
        return devices
    }
    
    public func getAllLocationsMainUser() -> [String: Location]{
        return locations
    }
    
    public func getAllPublicationsMainUser(completion: @escaping (_ publications: [String:[Publication]]) -> Void) {
        if let u = alpsUser, let d = alpsDevice {
            // let _ = Alps.DeviceAPI.getPublications
            //                (publications, error) -> Void in
            //
            //            }
            
            // XXX: ignore the returned device for now
            completion(publications)
        }
    }
    
    public func getAllSubscriptionsMainUser(completion: @escaping (_ subscriptions: [String:[Subscription]]) -> Void)  {
        if let u = alpsUser, let d = alpsDevice {
            // let _ = Alps.DeviceAPI.getPublications
            //                (publications, error) -> Void in
            //
            //            }
            
            // XXX: ignore the returned device for now
            completion(subscriptions)
        }
    }
    
    public func getExistingBeacons() -> [IBeaconDevice] {
        return beacons
    }
    
    public func registerDeviceToken(deviceToken: Data, deviceTokenString: String){
        notificationManager?.registerDeviceToken(deviceToken: deviceToken, deviceTokenString: deviceTokenString)
    }
    
    public func handleRemoteNotification(userInfo: [AnyHashable : Any]){
        notificationManager?.handleRemoteNotification(userInfo: userInfo)
    }
}
