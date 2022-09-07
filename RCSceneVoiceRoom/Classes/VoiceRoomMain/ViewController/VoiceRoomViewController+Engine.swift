//
//  VoiceRoomViewController+Engine.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/18.
//

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
    }
    
    private func handleReceivePickSeat(from: String) {
        var inviter = "房主"
        if managers.map(\.userId).contains(from) {
            inviter = "管理员"
        }
        let alertVC = UIAlertController(title: "是否同意上麦", message: "您被\(inviter)邀请上麦，是否同意？", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "同意", style: .default, handler: { _ in
            self.enterSeatIfAvailable()
            VoiceRoomNotification.agreeManagePick.send(content: from)
        }))
        alertVC.addAction(UIAlertAction(title: "拒绝", style: .cancel, handler: { _ in
            VoiceRoomNotification.rejectManagePick.send(content: from)
        }))
        
        if let fm = self.floatingManager, fm.showing {
            UIApplication.shared.keyWindow()?.rootViewController?.present(alertVC, animated: true)
        } else {
            topmostController().present(alertVC, animated: true)
        }
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
    
    func seatInfoDidUpdate(_ seatInfolist: [RCVoiceSeatInfo]) {
        seatList = seatInfolist
        print("seatinlist count is \(seatInfolist.count)")
    }
    
    
    func onSeatUserInfoDidUpdate(_ seatUserlist: [RCVoiceUserInfo]) {
        if seatUserlist.contains(where: { $0.userId == Environment.currentUserId }) {
            self.roomContainerAction?.disableSwitchRoom()
        } else if voiceRoomInfo.isOwner == false {
            self.roomContainerAction?.enableSwitchRoom()
        }
        
        self.onSeatUsers = seatUserlist;
    }
    
    
    func userDidEnterSeat(_ seatIndex: Int, user userId: String) {
        
    }
    
    func userDidLeaveSeat(_ seatIndex: Int, user userId: String) {
        
    }
    
    func seatDidMute(_ index: Int, isMute: Bool) {
    
    }
    
    func seatDidLock(_ index: Int, isLock: Bool) {
    }
    
    
    func userDidEnter(_ userId: String) {
        roomInfoView.roomUserIncrease()
    }
    
    func userDidExit(_ userId: String) {
        roomInfoView.roomUserDecrease()
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
    
    // will be deprecated
    func speakingStateDidChange(_ seatIndex: UInt, speakingState isSpeaking: Bool) {
        
    }
    
    // room distory call back
    func roomDidClosed() {
        isRoomClosed = true
        navigator(.voiceRoomAlert(title: "当前直播已结束",
                                  actions: [.confirm("确定")],
                                  alertType: alertTypeVideoAlreadyClose,
                                  delegate: self))
    }
    
    func messageDidReceive(_ message: RCMessage) {
        if message.content == nil { return }
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
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
        case .rejectManagePick:
            if content == Environment.currentUserId {
                SVProgressHUD.showError(withStatus: "用户拒绝邀请")
            }
        case .agreeManagePick:
            if content == Environment.currentUserId {
                SVProgressHUD.showSuccess(withStatus: "用户连线成功")
            }
        case .forbiddenAdd:
            SceneRoomManager.shared.forbiddenWords.append(content)
        case .forbiddenDelete:
            SceneRoomManager.shared.forbiddenWords.removeAll(where: { $0 == content })
        }
    }
    
    func pickSeatDidReceive(by userId: String) {
        handleReceivePickSeat(from: userId)
    }
    
    func kickSeatDidReceive(_ seatIndex: UInt) {
        SVProgressHUD.showSuccess(withStatus: "您已被抱下麦")
        if currentUserRole() == .creator {
            RCSceneMusic.stop()
        } else {
            roomState.connectState = .request
        }
    }
    
    func requestSeatDidAccept() {
        enterSeatIfAvailable()
    }
    
    func requestSeatDidReject() {
        SVProgressHUD.showError(withStatus: "您的连麦请求被拒绝")
    }
    
    
    func requestSeatListDidChange() {
        setupRequestStateAndMicOrderListState()
    }
     
    
    func invitationDidReceive(_ invitationId: String, from userId: String, content: String) {
    }
    
    func invitationDidAccept(_ invitationId: String) {
    }
    
    func invitationDidReject(_ invitationId: String) {
    }
    
    func invitationDidCancel(_ invitationId: String) {
    }
    
    func userDidKick(fromRoom targetId: String, byUserId userId: String) {
        roomInfoView.roomUserDecrease()
        if targetId == Environment.currentUserId {
            if managers.contains(where: { $0.userId == userId }) {
                RCSceneUserManager.shared.fetchUserInfo(userId: userId) { user in
                    SVProgressHUD.showInfo(withStatus: "您被管理员\(user.userName)踢出房间")
                }
            } else {
                SVProgressHUD.showInfo(withStatus: "您被踢出房间")
            }
            self.leaveRoom()
        }
    }
    
    func networkStatus(_ rtt: Int) {
        roomInfoView.updateNetworking(rtt: rtt)
    }    
}
