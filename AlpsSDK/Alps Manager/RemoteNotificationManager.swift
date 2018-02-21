//
//  RemoteNotificationManager.swift
//  AlpsSDK
//
//  Created by Wen on 07.11.17.
//  Copyright © 2018 Matchmore SA. All rights reserved.
//

import Foundation

protocol RemoteNotificationManagerDelegate: class {
    func didReceiveMatchUpdateForDeviceId(deviceId: String)
}

let kTokenKey = "kTokenKey"

public class RemoteNotificationManager: NSObject {
    
    private(set) weak var delegate: RemoteNotificationManagerDelegate?
    var deviceToken: String? {
        didSet {
            KeychainHelper.shared[kTokenKey] = self.deviceToken
        }
    }
    
    init(delegate: RemoteNotificationManagerDelegate) {
        self.deviceToken = KeychainHelper.shared[kTokenKey]
        super.init()
        self.delegate = delegate
    }
    
    func registerDeviceToken(deviceToken: String) {
        if self.deviceToken != deviceToken {
            self.deviceToken = deviceToken
            
            // TODO: Update mobile devices with device Token
        }
    }
    
    func process(pushNotification: [AnyHashable: Any]) {
        guard pushNotification["matchId"] != nil else { return }
        delegate?.didReceiveMatchUpdateForDeviceId(deviceId: "")
    }
}
