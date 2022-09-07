//
//  VoiceRoomViewController+RoomInfo.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/21.
//

import SVProgressHUD
import RCSceneRoom

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
        roomInfoView.delegate = self
    }
    
    @_dynamicReplacement(for: kvRoomInfo)
    private var inner_kvRoomInfo: RCVoiceRoomInfo? {
        get {
            return kvRoomInfo
        }
        set {
            kvRoomInfo = newValue
            if let info = newValue {
                updateRoomInfo(info: info)
            }
        }
    }
    
    private func updateRoomInfo(info: RCVoiceRoomInfo) {
        voiceRoomInfo.roomName = info.roomName
        roomState.isFreeEnterSeat = info.isFreeEnterSeat
        roomState.isSeatModeLess = (info.seatCount < 9)
        roomInfoView.updateRoom(info: voiceRoomInfo)
    }
}

extension VoiceRoomViewController: RoomInfoViewClickProtocol {
    func didFollowRoomUser(_ follow: Bool) {
        RCSceneUserManager.shared.refreshUserInfo(userId: voiceRoomInfo.userId) { followUser in
            guard follow else { return }
            RCSceneUserManager.shared.fetchUserInfo(userId: Environment.currentUserId) { [weak self] user in
                let message = RCChatroomFollow()
                message.userInfo = user.rcUser
                message.targetUserInfo = followUser.rcUser
                ChatroomSendMessage(message) { result in
                    switch result {
                    case .success:
                        self?.messageView.addMessage(message)
                    case .failure(let error):
                        SVProgressHUD.showError(withStatus: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func roomInfoDidClick() {
        navigator(.userList(room: voiceRoomInfo, delegate: self))
    }
}
