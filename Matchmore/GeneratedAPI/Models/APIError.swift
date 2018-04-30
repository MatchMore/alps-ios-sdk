//
// APIError.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation

open class APIError: JSONEncodable {
    public var code: Int32?
    public var message: String?

    public init() {}

    // MARK: JSONEncodable

    open func encodeToJSON() -> Any {
        var nillableDictionary = [String: Any?]()
        nillableDictionary["code"] = code?.encodeToJSON()
        nillableDictionary["message"] = message

        let dictionary: [String: Any] = APIHelper.rejectNil(nillableDictionary) ?? [:]
        return dictionary
    }
}