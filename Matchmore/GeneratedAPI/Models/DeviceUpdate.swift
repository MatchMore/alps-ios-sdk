//
// DeviceUpdate.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

/** Describes update of device, it allows to change name of device and device token (only in case of mobile devices) */
open class DeviceUpdate: JSONEncodable {
    /** New device name (optional) */
    public var name: String?
    /** Token used for pushing matches. The token needs to be prefixed with &#x60;apns://&#x60; or &#x60;fcm://&#x60; dependent on the device or channel the match should be pushed with */
    public var deviceToken: String?

    public init() {}

    // MARK: JSONEncodable

    open func encodeToJSON() -> Any {
        var nillableDictionary = [String: Any?]()
        nillableDictionary["name"] = name
        nillableDictionary["deviceToken"] = deviceToken

        let dictionary: [String: Any] = APIHelper.rejectNil(nillableDictionary) ?? [:]
        return dictionary
    }
}