//
//  VoiceRoomViewController+Engine.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/18.
//

import Combine

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
    }
}

//MARK: - Voice Room Delegate
extension VoiceRoomViewController: RCVoiceRoomDelegate {
    func roomDidOccurError(withDetails error: RCVoiceRoomError) {
        SVProgressHUD.showError(withStatus: error.message)
    }
    
    func roomKVDidReady() {
        if currentUserRole() == .creator {
            enterSeat(index: 0) {
                [weak self] in
                self?.getPKStatus()
            }
        } else {
            getPKStatus()
        }
        roomInfoView.userNumberNeedUpdate()
    }
    
    func roomInfoDidUpdate(_ roomInfo: RCVoiceRoomInfo) {
        kvRoomInfo = roomInfo
    }
    
    func roomDidClosed() {
        isRoomClosed = true
        navigator(.voiceRoomAlert(title: "当前直播已结束",
                                  actions: [.confirm("确定")],
                                  alertType: alertTypeVideoAlreadyClose,
                                  delegate: self))
    }
    
    
    func seatInfoDidUpdate(_ seatInfolist: [RCVoiceSeatInfo]) {
        seatList = seatInfolist
        print("seatinlist count is \(seatInfolist.count)")
        self.updateChangesWithSeatUser()
    }
    
    
    func onSeatUserInfoDidUpdate(_ seatUserlist: [RCVoiceUserInfo]) {
        if seatUserlist.contains(where: { $0.userId == Environment.currentUserId }) {
            self.roomContainerAction?.disableSwitchRoom()
        } else if voiceRoomInfo.isOwner == false {
            self.roomContainerAction?.enableSwitchRoom()
        }
        self.onSeatUsers = seatUserlist;
        self.updateChangesWithSeatUser()
    }

    
    func userDidEnterSeat(_ seatIndex: Int, user userId: String) {
        
    }
    
    func userDidLeaveSeat(_ seatIndex: Int, user userId: String) {
        
    }
    
    func seatDidMute(_ index: Int, isMute: Bool) {
    
    }
    
    func seatDidLock(_ index: Int, isLock: Bool) {
        
    }
    
    func seatUserAudio(_ index: Int, userId: String, isDisable: Bool) {
        
    }
    
    func userDidEnter(_ userId: String) {
        
    }
    
    func userDidExit(_ userId: String) {
        
    }
    
    func memberCountDidChange(_ memberCount: Int) {
        roomInfoView.updateUser(count: memberCount)
    }

    func seatSpeakingStateChanged(_ speaking: Bool, at index: Int, audioLevel level: Int) {
        let isSpeaking = level > 4
        print("speaking:\(isSpeaking),index:\(index),audioLevel:\(level)")
        if index == 0 {
            ownerView.setSpeakingState(isSpeaking: isSpeaking)
            if let fm = self.floatingManager {
                fm.setSpeakingState(isSpeaking: speaking)
            }
        } else {
            if let cell = collectionView.cellForItem(at: IndexPath(item: Int(index - 1), section: 0)) as? VoiceRoomSeatCollectionViewCell {
                cell.setSpeakingState(isSpeaking: isSpeaking)
            }
        }
    }

    
    func roomNotificationDidReceive(_ name: String, content: String) {
        guard let type = VoiceRoomNotification(rawValue: name) else {
            return
        }
        switch type {
        case .backgroundChanged:
            NotificationNameRoomBackgroundUpdated.post((voiceRoomInfo.roomId, content))
        case .mangerlistNeedRefresh:
            fetchmanagers()
        case .forbiddenAdd:
            SceneRoomManager.shared.forbiddenWords.append(content)
        case .forbiddenDelete:
            SceneRoomManager.shared.forbiddenWords.removeAll(where: { $0 == content })
        }
    }
    

    func messageDidReceive(_ message: RCMessage) {
        if message.content == nil { return }
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
        }
    }
    
    func kickSeatDidReceive(_ seatIndex: UInt, userId: String, content: String) {
        SVProgressHUD.showSuccess(withStatus: "您已被抱下麦")
        if currentUserRole() == .creator {
            RCSceneMusic.stop()
        } else {
            roomState.connectState = .request
        }
    }
    
    func userDidKick(fromRoom operatorId: String, userId: String, content: String) {
        if userId == Environment.currentUserId {
            if managers.contains(where: { $0.userId == operatorId }) {
                RCSceneUserManager.shared.fetchUserInfo(userId: operatorId) { user in
                    SVProgressHUD.showInfo(withStatus: "您被管理员\(user.userName)踢出房间")
                }
            } else {
                SVProgressHUD.showInfo(withStatus: "您被踢出房间")
            }
            self.leaveRoom()
        }
    }
    
    
    func requestSeatResponse(_ isAccept: Bool, targetIndex: Int, content: String) {
        if isAccept {
            if targetIndex == -1  {
                enterSeatIfAvailable()
            } else {
                enterSeat(index: targetIndex)
            }
        } else {
            SVProgressHUD.showError(withStatus: "您的连麦请求被拒绝")
        }
    }

    func requestSeatListDidChange() {
        setupRequestStateAndMicOrderListState()
    }
     
    func invitationDidReceive(_ invitationId: String, from userId: String, content: String) {
        var inviter = "房主"
        if managers.map(\.userId).contains(userId) {
            inviter = "管理员"
        }
        let alertVC = UIAlertController(title: "是否同意上麦", message: "您被\(inviter)邀请上麦，是否同意？", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "同意", style: .default, handler: { _ in
            RCVoiceRoomEngine.sharedInstance().responseInvitation(invitationId, accept: true, content: content) {
                self.enterSeatIfAvailable()
            } error: { code, msg in
            }
        }))
        alertVC.addAction(UIAlertAction(title: "拒绝", style: .cancel, handler: { _ in
            RCVoiceRoomEngine.sharedInstance().responseInvitation(invitationId, accept: false, content: content) {
                
            } error: { code, msg in
            }
        }))
        
        if let fm = self.floatingManager, fm.showing {
            UIApplication.shared.keyWindow()?.rootViewController?.present(alertVC, animated: true)
        } else {
            topmostController().present(alertVC, animated: true)
        }
    }
    

    
    func invitationDidCancel(_ invitationId: String) {
        
    }
    
    /// 邀请得到响应
    func invitationDidRespones(_ isAccept: Bool, invitationId: String, content: String) {
        if isAccept {
            SVProgressHUD.showError(withStatus: "用户接受邀请")
        } else {
            SVProgressHUD.showError(withStatus: "用户拒绝邀请")
        }
    }
    
    func streamTypeChange(_ streamType: RCVoiceStreamType) {
        
    }
    
    func playCDNStream(_ roomId: String, isPlay: Bool) {
        
    }
    
    func networkStatus(_ status: RCRTCStatusForm) {
        roomInfoView.updateNetworking(rtt: status.rtt)
    }
}
