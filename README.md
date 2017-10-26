# Alps iOS SDK

`AlpsSDK` is a contextualized publish/subscribe model which can be used to model any geolocated or proximity based mobile application. Save time and make development easier by using our SDK. We are built on Apple Core Location technologies and we also provide iBeacons compatibility.

## Versioning

Only compatible with Swift 3.

Alps SDK requires iOS 7+, if you want to use iBeacons.

## Installation

Alps is available through [CocoaPods](http://cocoapods.org), simply add the following
line to your Podfile:

    pod 'AlpsSDK', :git => 'https://github.com/MatchMore/alps-ios-sdk.git', :tag => '0.4.0'

## Technical overview

The `AlpsManager` class is built as such that it provides you all the functions you need to use our SDK.

Features of Alps SDK are divided into two parts: Asynchronous calls and dynamic calls.

### Asynchronous calls

All the asynchronous functions calls our cloud service and return a completion for you.

### Dynamic calls

Everytime you call an asynchronous function and it succeeds, our SDK stores it. To gain speed, we allow you to get access(read only) to these stored values.

## Usage

```swift
// hold a strong reference to the AlpsManager, as you probably will have to call it in many 
// differents views in your application
// we advice you to initiate the AlpsManager in the AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {

let APIKEY = "ea0df90a-db0a-11e5-bd35-3bd106df139b" // <- Please provide a valid Matchmore
// Application Api-key, obtain it for free on dev.matchmore.io, see the README.md 
// file for more informations

var alps: AlpsManager!
var locationManager = CLLocationManager()

// ...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
// Override point for customization after application launch.
if APIKEY.isEmpty {
fatalError("To run this project, please provide a valid Matchmore Application Api-key. Obtain it for free on dev.matchmore.io, see the README.md file for more informations")
}else{
alps = AlpsManager(apiKey: APIKEY, clLocationManager : locationManager)
}
return true
}

// ...
}
```

Here is an example on how to create your first user with device and get a match.
Please refer to documentation "tutorial" to get a full explanation on this example.

```swift
// ...

// Create a User
appDelegate.alps.createUser("Alice", completion: {(_ user) in
if let u = user {
print(u.id)
// Create a MobileDevice
// Using this function inside of createUser closure is important, we want to make sure user is
// created before calling the creation of a mobile device. This imply to publication and
// subscription too. We want to make sure user and device are initiated before publishing or
// subscribing.
self.appDelegate.alps.createMobileDevice(name: "Alice's mobile device", platform: "iOS 9.0", deviceToken: "personnalUUID", latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, completion: {
(_ mobileDevice) in
if let md = mobileDevice{
print(md.id)
// Create a publication
let properties = ["mood": "happy"]
self.appDelegate.alps.createPublication(topic: "tutorial", range: 1000, duration: 300, properties: properties, completion: {
(_ publication) in
if let p = publication {
print(p.id)
}
})

// Create a subscription
let selector = "mood = 'happy'"
self.appDelegate.alps.createSubscription(topic: "tutorial", selector: selector, range: 1000, duration: 300, completion: {
(_ subscription) in
if let s = subscription {
print(s.id)
}
})

// Starts updating mobile device location to our cloud service
self.appDelegate.alps.startUpdatingLocation()
// Get the matches
self.appDelegate.alps.startMonitoringMatches()
// onMatch function is called everytime a match occurs.
self.appDelegate.alps.onMatch(completion: {
(_ match) in
print(match.id)
})
}
})
}
})

// ...
```

## Example

To run the example project, clone the repo, and run \`pod install\` from
the Example directory first.

## Documentation

See the [http://dev.matchmore.com/documentation/api](http://dev.matchmore.com/documentation/api) or consult our website for further information [http://dev.matchmore.com/](http://dev.matchmore.com/)

## Author

rk, rafal.kowalski@mac.com


## License

Alps is available under the MIT license. See the LICENSE file for more info.
