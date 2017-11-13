//
//  Expirable.swift
//  AlpsSDK
//
//  Created by Maciej Burda on 13/11/2017.
//  Copyright © 2017 Alps. All rights reserved.
//

import Foundation
import Alps

protocol Expirable {
    var duration: Double? { get set }
    var createdAt: Int64? { get set }
    
    var isExpired: Bool { get }
}

extension Expirable {
    var isExpired: Bool {
        guard let duration = self.duration, let createdAt = self.createdAt else { return true }
        let nowTimeInterval = Date().nowTimeInterval()
        return Int64(duration * 1000) < (nowTimeInterval - createdAt)
    }
}

extension Subscription: Expirable {
}

extension Publication: Expirable {
}

extension Array where Element: Expirable {
    var withoutExpired: [Element] {
        return self.filter {
            $0.isExpired == false
        }
    }
}
