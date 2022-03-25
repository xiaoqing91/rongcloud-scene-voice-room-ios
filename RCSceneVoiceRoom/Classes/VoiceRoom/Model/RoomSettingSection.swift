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

enum RoomSettingItem {
    case lockRoom(Bool)
    case muteAllSeat(Bool)
    case lockAllSeat(Bool)
    case muteSelf(Bool)
    case music
    case videoSetting
    case isFreeEnterSeat(Bool)
    case roomTitle
    case roomBackground
    case lessSeatMode(Bool)
    case forbidden
    case suspend
    case notice
}

extension RoomSettingItem {
    var title: String {
        switch self {
        case let .lockRoom(isLock):
            return isLock ? "房间解锁" : "房间上锁"
        case let .muteAllSeat(isMute):
            return isMute ? "解锁全麦" : "全麦锁麦"
        case let .lockAllSeat(isLock):
            return isLock ? "解锁全座" : "全麦锁座"
        case let .muteSelf(isMute):
            return isMute ? "取消静音" : "静音"
        case let .isFreeEnterSeat(isFree):
            return isFree ? "申请上麦" : "自由上麦"
        case .roomTitle:
            return "房间标题"
        case .roomBackground:
            return "房间背景"
        case let .lessSeatMode(isLess):
            return (isLess ? "设置8个座位" : "设置4个座位")
        case .music:
            return "音乐"
        case .videoSetting:
            return "视频设置"
        case .forbidden:
            return "屏蔽词"
        case .suspend:
            return "暂停直播"
        case .notice:
            return "房间公告"
        }
    }
    
    var image: UIImage? {
        switch self {
        case let .lockRoom(isLock):
            return isLock ?
            RCSCAsset.Images.voiceroomSettingUnlockroom.image :
            RCSCAsset.Images.voiceroomSettingLockroom.image
        case let .muteAllSeat(isMute):
            return isMute ?
            RCSCAsset.Images.voiceroomSettingUnmuteall.image :
            RCSCAsset.Images.voiceroomSettingMuteall.image
        case let .lockAllSeat(isLock):
            return isLock ?
            RCSCAsset.Images.voiceroomSettingUnlockallseat.image :
            RCSCAsset.Images.voiceroomSettingLockallseat.image
        case let .muteSelf(isMute):
            return isMute ?
            RCSCAsset.Images.voiceroomSettingUnmute.image :
            RCSCAsset.Images.voiceroomSettingMute.image
        case .music:
            return RCSCAsset.Images.voiceroomSettingMusic.image
        case .videoSetting:
            return RCSCAsset.Images.voiceroomSettingLockroom.image
        case let .isFreeEnterSeat(isFree):
            return isFree ?
            RCSCAsset.Images.voiceroomSettingFreemode.image :
            RCSCAsset.Images.voiceroomSettingApplymode.image
        case .roomTitle:
            return RCSCAsset.Images.voiceroomSettingTitle.image
        case .roomBackground:
            return RCSCAsset.Images.voiceroomSettingBackground.image
        case let .lessSeatMode(isLess):
            return isLess ?
            RCSCAsset.Images.voiceroomSettingAddseat.image :
            RCSCAsset.Images.voiceroomSettingMinusseat.image
        case .forbidden:
            return RCSCAsset.Images.forbiddenTextIcon.image
        case .suspend:
            return RCSCAsset.Images.voiceroomSettingSuspend.image
        case .notice:
            return RCSCAsset.Images.voiceroomSettingNotice.image
        }
    }
}
