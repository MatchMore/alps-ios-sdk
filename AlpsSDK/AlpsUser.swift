//
//  AlpsUser.swift
//  Alps
//
//  Created by Rafal Kowalski on 21/12/2016
//  Copyright © 2016 Alps. All rights reserved.
//

import Foundation
import Alps

open class AlpsUser {
    public let manager: AlpsManager
    public let user: User

    public init(manager: AlpsManager, user: User) {
        self.manager = manager
        self.user = user
    }

    public func id() -> String {
        return user.id!
    }
}
