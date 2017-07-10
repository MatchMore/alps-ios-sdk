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
    let scalpsEndpoint = "https://api.adjago.io/v02"

    // Put setup code here. This method is called before the invocation of each test method in t
    let apiKey: String
    var locationManager: LocationManager? = nil
    var matchMonitor: MatchMonitor? = nil

    // FIXME: add the world id when it's there
    // var world: World
    var users: [User] = []
    var alpsUser: AlpsUser?
    var devices: [Device] = []
    var alpsDevice: AlpsDevice?
    var locations: [DeviceLocation] = []
    var publications: [Publication] = []
    var subscriptions: [Subscription] = []

    public convenience init(apiKey: String) {
        self.init(apiKey: apiKey, clLocationManager: CLLocationManager())
    }

    public init(apiKey: String, clLocationManager: CLLocationManager) {
        self.apiKey = apiKey
        self.headers = defaultHeaders.merged(with: ["api-key": apiKey])
        self.locationManager = LocationManager(alpsManager: self, locationManager: clLocationManager)
        self.matchMonitor = MatchMonitor(alpsManager: self)

        AlpsAPI.basePath = scalpsEndpoint
        AlpsAPI.customHeaders = headers
    }

    public func createUser(_ userName: String, completion: @escaping (_ user: User?) -> Void) {
        let userCompletion = completion
        let _ = Alps.UsersAPI.createUser(name: userName) {
            (user, error) -> Void in
            if let u = user {
                self.users.append(u)
                self.alpsUser = AlpsUser(manager: self, user: self.users[0])
            }
            userCompletion(user)
        }
    }

    public func createDevice(name: String, platform: String, deviceToken: String,
                             latitude: Double, longitude: Double, altitude: Double,
                             horizontalAccuracy: Double, verticalAccuracy: Double,
                             completion: @escaping (_ device: Device?) -> Void) {
        let userCompletion = completion
        if let u = alpsUser {
            let _ = Alps.UserAPI.createDevice(userId: u.user.userId!, name: name, platform: platform,
                                                deviceToken: deviceToken, latitude: latitude, longitude: longitude,
                                                altitude: altitude, horizontalAccuracy: horizontalAccuracy,
                                                verticalAccuracy: verticalAccuracy) {
                (device, error) -> Void in
                if let d = device {
                    self.devices.append(d)
                    self.alpsDevice = AlpsDevice(manager: self, user: u.user, device: self.devices[0])
                }
                userCompletion(device)
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }
    }

    public func createPublication(userId: String, deviceId: String, topic: String, range: Double, duration: Double, properties: [String: String],
                                  completion: @escaping (_ publication: Publication?) -> Void) {
        let userCompletion = completion

        let _ = Alps.DeviceAPI.createPublication(userId: userId, deviceId: deviceId,
                                                  topic: topic, range: range, duration: duration,
                                                  properties: properties) {
            (publication, error) -> Void in

            userCompletion(publication)
        }
    }

    public func createPublication(topic: String, range: Double, duration: Double, properties: [String: String],
                                  completion: @escaping (_ publication: Publication?) -> Void) {
        let userCompletion = completion

        if let u = alpsUser, let d = alpsDevice {
            let _ = Alps.DeviceAPI.createPublication(userId: u.user.userId!, deviceId: d.device.deviceId!,
                                                       topic: topic, range: range, duration: duration,
                                                       properties: properties) {
                (publication, error) -> Void in

                if let p = publication {
                    self.publications.append(p)
                }

                userCompletion(publication)
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user and/or device hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }
    }


    public func createSubscription(userId: String, deviceId: String, topic: String, selector: String, range: Double, duration: Double,
                                   completion: @escaping (_ subscription: Subscription?) -> Void) {
        let userCompletion = completion

            let _ = Alps.DeviceAPI.createSubscription(userId: userId, deviceId: deviceId,
                                                        topic: topic, selector: selector, range: range,
                                                        duration: duration) {
                (subscription, error) -> Void in
                userCompletion(subscription)
            }
    }

    public func createSubscription(topic: String, selector: String, range: Double, duration: Double,
                                   completion: @escaping (_ subscription: Subscription?) -> Void) {
        let userCompletion = completion

        if let u = alpsUser, let d = alpsDevice {
            let _ = Alps.DeviceAPI.createSubscription(userId: u.user.userId!, deviceId: d.device.deviceId!,
                                                        topic: topic, selector: selector, range: range,
                                                        duration: duration) {
                (subscription, error) -> Void in

                if let p = subscription {
                    self.subscriptions.append(p)
                }

                userCompletion(subscription)
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user and/or device hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }
    }
    
    public func updateLocation(userId:String, deviceId: String, latitude: Double, longitude: Double, altitude: Double,
                               horizontalAccuracy: Double, verticalAccuracy: Double,
                               completion: @escaping (_ location: DeviceLocation?) -> Void) {
        let userCompletion = completion

            let _ = Alps.DeviceAPI.createLocation(userId: userId, deviceId: deviceId,
                                                    latitude: latitude, longitude: longitude, altitude: altitude,
                                                    horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy) {
                (location, error) -> Void in
                userCompletion(location)
            }
    }

    public func updateLocation(latitude: Double, longitude: Double, altitude: Double,
                               horizontalAccuracy: Double, verticalAccuracy: Double,
                               completion: @escaping (_ location: DeviceLocation?) -> Void) {
        let userCompletion = completion

        if let u = alpsUser, let d = alpsDevice {
            let _ = Alps.DeviceAPI.createLocation(userId: u.user.userId!, deviceId: d.device.deviceId!,
                                                    latitude: latitude, longitude: longitude, altitude: altitude,
                                                    horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy) {
                (location, error) -> Void in

                if let l = location {
                    self.locations.append(l)
                }

                userCompletion(location)
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

    public func getAllMatches(completion: @escaping (_ matches: Matches) -> Void) {
        let userCompletion = completion

        if let u = alpsUser, let d = alpsDevice {
            let _ = Alps.DeviceAPI.getMatches(userId: u.user.userId!, deviceId: d.device.deviceId!) {
                (matches, error) -> Void in

                if let ms = matches {
                    // self.matches.append(ms)
                    userCompletion(ms)
                }
            }
        } else {
            // XXX: error handling using exceptions?
            print("Alps user and/or device hasn't been initialized yet!")
            // throw AlpsManagerError.userNotIntialized
        }

    }

    public func onMatch(completion: @escaping (_ match: Match) -> Void) {
        if let mm = matchMonitor {
            mm.onMatch(completion: completion)
        }
    }



    func getUser(_ userId: String, completion: @escaping (_ user: User) -> Void) {
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

    func getUser(completion: @escaping (_ user: User) -> Void)  {
        if let u = alpsUser {
            completion(u.user)
        } else {
            print("Alps user doesn't exist!")
            //            // throw AlpsManagerError.userNotIntialized
        }
    }

    func getDevice(_ deviceId: String, completion: @escaping (_ device: Device) -> Void) {

        if let u = alpsUser, let d = alpsDevice {
            let _ = Alps.UserAPI.getDevice(userId: u.user.userId!, deviceId: d.device.deviceId!) {
                (device, error) -> Void in

            }
            // XXX: ignore the returned device for now
            completion(d.device)
        }
    }

    func getDevice(completion: @escaping (_ device: Device) -> Void)  {
        if let u = alpsUser, let d = alpsDevice {
            let _ = Alps.UserAPI.getDevice(userId: u.user.userId!, deviceId: d.device.deviceId!) {
                (device, error) -> Void in

            }

            // XXX: ignore the returned device for now
            completion(d.device)
        }
    }
    func getPublication(_ userId:String, deviceId:String, publicationId: String, completion: @escaping (_ publication: Publication) -> Void) {
        let _ = Alps.PublicationAPI.getPublication(userId: userId, deviceId: deviceId, publicationId: publicationId) {
            (publication, error) -> Void in
              if let p = publication {
                  completion(p)
              }else {
                  print("This publication doesn't exist!")
              }
        }
    }
    
    func deletePublication(_ userId:String, deviceId:String, publicationId: String, completion: @escaping () -> Void) {
        let _ = Alps.PublicationAPI.deletePublication(userId: userId, deviceId: deviceId, publicationId: publicationId) {
            (error) -> Void in
            if let e = error {
                print("Impossible to delete the publication!")
            }else {
                completion()
            }
        }
    }

    func getAllPublications(completion: @escaping (_ publications: [Publication]) -> Void) {
        if let u = alpsUser, let d = alpsDevice {
            // let _ = Alps.DeviceAPI.getPublications
//                (publications, error) -> Void in
//
//            }

            // XXX: ignore the returned device for now
            completion(publications)
        }
    }

    func getAllSubscriptions(completion: @escaping (_ subscriptions: [Subscription]) -> Void)  {
        if let u = alpsUser, let d = alpsDevice {
            // let _ = Alps.DeviceAPI.getPublications
            //                (publications, error) -> Void in
            //
            //            }

            // XXX: ignore the returned device for now
            completion(subscriptions)
    func getAllPublicationsForDevice(_ userId:String, deviceId: String, completion: @escaping (_ publications: [Publication]) -> Void) {
        let _ = Alps.PublicationAPI.getPublications(userId: userId, deviceId: deviceId) {
            (publications, error) -> Void in
            if let p = publications{
                completion(p)
            }else {
                print("Can't find publications for this device")
            }
        }
    }

    func getSubscription(_ userId:String, deviceId: String, subscriptionId: String, completion: @escaping (_ subscription: Subscription) -> Void) {
        let _ = Alps.SubscriptionAPI.getSubscription(userId: userId, deviceId: deviceId, subscriptionId: subscriptionId) {
            (subscription, error) -> Void in
            if let s = subscription {
                completion(s)
            }else {
                print("This subscription doesn't exist!")
            }
        }
    }

    func deleteSubscription(_ userId:String, deviceId:String, subscriptionId: String, completion: @escaping () -> Void) {
        let _ = Alps.SubscriptionAPI.deleteSubscription(userId: userId, deviceId: deviceId, subscriptionId: subscriptionId) {
            (error) -> Void in
            if let e = error {
                print("Impossible to delete the subscription!")
            }else {
                completion()
            }
        }
    }
    
    func getAllSubscriptionsForDevice(_ userId:String, deviceId: String, completion: @escaping (_ subscriptions: [Subscription]) -> Void) {
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
        if let lm = locationManager {
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
        locationManager?.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        locationManager?.stopUpdatingLocation()
    }
}
