//
//  RCSceneVoiceRoom.swift
//  RCSceneVoiceRoom
//
//  Created by shaoshuai on 2022/2/26.
//

import UIKit
import XCoordinator
import RCSceneRoom

public func RCVoiceRoomController(room: RCSceneRoom, creation: Bool = false) -> RCRoomCycleProtocol {
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
    
    func joinRoom(_ completion: @escaping (Result<Void, ReactorError>) -> Void) {
        SceneRoomManager.shared.voice_join(voiceRoomInfo.roomId, complation: completion)
    }
    
    func leaveRoom(_ completion: @escaping (Result<Void, ReactorError>) -> Void) {
        SceneRoomManager.shared.voice_leave(completion)
    }
    
    func descendantViews() -> [UIView] {
        return [messageView.tableView]
    }
}
