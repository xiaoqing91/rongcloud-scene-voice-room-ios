//
//  RoomSettingView.swift
//  RCE
//
//  Created by 叶孤城 on 2021/5/6.
//

import UIKit


enum ConnectMicState {
    case request
    case waiting
    case connecting
    
    var image: UIImage? {
        switch self {
        case .request:
            return RCSCAsset.Images.connectMicStateNone.image
        case .waiting:
            return RCSCAsset.Images.connectMicStateWaiting.image
        case .connecting:
            return RCSCAsset.Images.connectMicStateConnecting.image
        }
    }
}

enum VoiceRoomPKRole {
    case inviter
    case invitee
    case audience
}

struct VoiceRoomPKInfo {
    let inviterId: String
    let inviteeId: String
    let inviterRoomId: String
    let inviteeRoomId: String
    
    func currentUserRole() -> VoiceRoomPKRole {
        if Environment.currentUserId == inviterId {
            return .inviter
        }
        if Environment.currentUserId == inviteeId {
            return .invitee
        }
        return .audience
    }
}

struct RoomSettingState {
    var isMutePKUser = false {
        didSet {
            mutePKStateChanged?(isMutePKUser)
        }
    }
    var lastInviteUserId: String?
    var lastInviteRoomId: String?
    var isPrivate = false
    var isMuteAll = false
    var isLockAll = false
    var isSilence = false
    var isCloseSelfMic = false
    var isFreeEnterSeat = false
    var isSeatModeLess = false
    var isEnterSeatWaiting = false
    var currentPKInfo: VoiceRoomPKInfo?
    var connectState: ConnectMicState = .request {
        didSet {
            debugPrint("connectState: \(connectState)")
            if connectState != oldValue {
                connectStateChanged?(connectState)
            }
        }
    }
    var pkConnectState: ConnectMicState = .request {
        didSet {
            switch pkConnectState {
            case .request:
                currentPKInfo = nil
                lastInviteRoomId = nil
                lastInviteUserId = nil
            case .connecting:
                lastInviteRoomId = nil
                lastInviteUserId = nil
            case .waiting:
                currentPKInfo = nil
            }
            pkConnectStateChanged?(pkConnectState)
        }
    }
    var connectStateChanged:((ConnectMicState) -> Void)?
    var pkConnectStateChanged:((ConnectMicState) -> Void)?
    var mutePKStateChanged:((Bool) -> Void)?
    
    init(room: VoiceRoom) {
        isPrivate = room.isPrivate == 1
    }
    
    mutating func update(from state: VoiceRoomState) {
        isMuteAll = state.applyAllLockMic
        isLockAll = state.applyAllLockSeat
        isFreeEnterSeat = !state.applyOnMic
        isSilence = state.setMute
        isSeatModeLess = state.setSeatNumber < 9
    }
    
    func isPKOngoing() -> Bool {
        return currentPKInfo != nil
    }
}
