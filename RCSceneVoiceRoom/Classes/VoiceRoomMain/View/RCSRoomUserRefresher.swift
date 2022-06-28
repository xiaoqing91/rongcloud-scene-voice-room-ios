//
//  RCSRoomUserRefresher.swift
//  RCSceneVoiceRoom
//
//  Created by shaoshuai on 2022/6/28.
//

import UIKit

public var RCSRoomEnableAutoCalibrateUserCount: Bool = true

protocol RCSRoomUserCalibratorDelegate: AnyObject {
    func userNumberNeedUpdate()
}

class RCSRoomUserCalibrator: NSObject {
    
    weak var delegate: RCSRoomUserCalibratorDelegate?
    
    private var workItem: DispatchWorkItem?
    
    private var lastTime: TimeInterval = 0
    
    var outerUserCount: Int = 0 {
        didSet {
            let currentDelayTime = delayTime(outerUserCount)
            if lastTime == 0 {
                let delayTime = Double(currentDelayTime)
                workItem = DispatchWorkItem { [weak self] in
                    self?.delegate?.userNumberNeedUpdate()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime,
                                              execute: workItem!)
                lastTime = Date().timeIntervalSince1970
            } else {
                let lastDelayTime = delayTime(oldValue)
                if lastDelayTime == currentDelayTime {
                    return
                }
                workItem?.cancel()
                workItem = nil
                let currentTime = Date().timeIntervalSince1970
                let passTime = currentTime - lastTime
                let delayTime = max(Double(currentDelayTime) - passTime, 2)
                workItem = DispatchWorkItem { [weak self] in
                    self?.delegate?.userNumberNeedUpdate()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime,
                                              execute: workItem!)
                lastTime = currentTime
            }
        }
    }
    
    init(_ delegate: RCSRoomUserCalibratorDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    private func delayTime(_ count: Int) -> Int {
        guard RCSRoomEnableAutoCalibrateUserCount else {
            return Int(INT_MAX)
        }
        if count < 50 {
            return 10
        }
        if count < 500 {
            return 100
        }
        if count < 5000 {
            return 600
        }
        return 3600
    }
}
