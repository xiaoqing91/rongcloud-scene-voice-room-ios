//
//  RCSceneVoiceRoom.swift
//  RCSceneVoiceRoom
//
//  Created by shaoshuai on 2022/2/26.
//

import RCSceneRoom

public var RCSceneVoiceRoomEnableSwitchableBackgroundImage = false

public func RCVoiceRoomController(room: RCSceneRoom, creation: Bool = false) -> RCRoomCycleProtocol {
    RCSceneIMMessageRegistration()
    return VoiceRoomViewController(roomInfo: room,
                                   isCreate: creation)
    
}

extension VoiceRoomViewController: RCRoomCycleProtocol {
    func setRoomContainerAction(action: RCRoomContainerAction) {
        self.roomContainerAction = action
    }
    
    func setRoomFloatingAction(action: RCSceneRoomFloatingProtocol) {
        self.floatingManager = action
    }
    
    func joinRoom(_ completion: @escaping (Result<Void, RCSceneError>) -> Void) {
        SceneRoomManager.shared.voice_join(voiceRoomInfo.roomId, complation: completion)
    }
    
    func leaveRoom(_ completion: @escaping (Result<Void, RCSceneError>) -> Void) {
        SceneRoomManager.shared.voice_leave(completion)
    }
    
    func descendantViews() -> [UIView] {
        return [messageView.tableView]
    }
}

fileprivate var isIMMessageRegistration = false
fileprivate func RCSceneIMMessageRegistration() {
    if isIMMessageRegistration { return }
    isIMMessageRegistration = true
    RCChatroomMessageCenter.registerMessageTypes()
    RCIM.shared().registerMessageType(RCGiftBroadcastMessage.self)
    RCIM.shared().registerMessageType(RCPKGiftMessage.self)
    RCIM.shared().registerMessageType(RCPKStatusMessage.self)
    RCIM.shared().registerMessageType(RCShuMeiMessage.self)
}
