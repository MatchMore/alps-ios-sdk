//
//  MatchMonitor.swift
//  Alps
//
//  Created by Rafal Kowalski on 28/02/2017
//  Copyright © 2017 Alps. All rights reserved.
//

import Alps

import Foundation

class MatchMonitor {
    let alpsManager: AlpsManager
    var timer: Timer = Timer()
    var deliveredMatches = Set<Match>()
    var onMatchClosure: ((_ match: Match) -> Void)

    convenience init(alpsManager: AlpsManager) {
        self.init(alpsManager: alpsManager, onMatch: {
            (_ match: Match) in NSLog("Got a match: \(match)")
        })
    }

    init(alpsManager: AlpsManager, onMatch: @escaping ((_ match: Match) -> Void)) {
        self.alpsManager = alpsManager
        self.onMatchClosure = onMatch
    }

    public func onMatch(completion: @escaping (_ match: Match) -> Void) {
        onMatchClosure = completion
    }

    public func startMonitoringMatches() {
        self.timer = Timer.scheduledTimer(
          timeInterval: 1.0,
          target: self,
          selector: #selector(MatchMonitor.checkMatches),
          userInfo: nil,
          repeats: true)
    }

    public func stopMonitoringMatches() {
        self.timer.invalidate()
    }

    @objc func checkMatches() {
//        NSLog("checking matches")
        alpsManager.getAllMatches {
            (_ matches: Matches) in
//            NSLog("got all matches from the cloud: \(matches)")

            for m in matches {
                if !self.deliveredMatches.contains(m) {
//                    NSLog("deliver this match: \(m)")
                    self.onMatchClosure(m)
                    self.deliveredMatches.insert(m)
                }
            }
        }
    }

}
