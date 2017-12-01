//
//  MatchDelegate.swift
//  AlpsExample
//
//  Created by Maciej Burda on 07/11/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AlpsSDK
import Alps

class MatchDelegate: AlpsDelegate {
    var onMatch: OnMatchClosure?
    init(_ onMatch: @escaping OnMatchClosure) {
        self.onMatch = onMatch
    }
}
