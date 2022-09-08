//
//  VoiceRoomViewController+Users.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/21.
//

import SVProgressHUD
import RCVoiceRoomLib

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
        micButton.micState = voiceRoomInfo.isOwner ? .user : .request
        roomState.connectStateChanged = {
           [weak self] state in
            if let room = self?.voiceRoomInfo, room.isOwner {
                self?.micButton.micState = .user
            } else {
                switch state {
                case .request: self?.micButton.micState = .request
                case .waiting: self?.micButton.micState = .waiting
                case .connecting: self?.micButton.micState = .connecting
                }
            }
            if state == .connecting {
                if let room = self?.voiceRoomInfo {
                    RCSensorAction.connectionWithDraw(room).trigger()
                }
                RCVoiceRoomEngine.sharedInstance().cancelRequestSeat {} error: { code, msg in }
            }
        }
    }
    
    @objc func handleMicButtonClick() {
        if voiceRoomInfo.isOwner {
            handleMicOrderClick()
        } else {
            audienceTapMicToRequestSeat()
        }
    }
    
    @objc private func handleMicOrderClick() {
        guard !roomState.isPKOngoing() else {
            SVProgressHUD.showError(withStatus: "当前 PK 中，无法进行该操作")
            return
        }
        
        let onSeatUserIds = self.onSeatUsers.map { $0.userId }
        let requesterIds = requesterInfos.compactMap(\.userId)
        
        let dest: RCNavigation = .requestOrInvite(roomId: voiceRoomInfo.roomId,
                                                        delegate: self,
                                                        showPage: 0,
                                                        onSeatUserIds: onSeatUserIds,
                                                        requesterIds: requesterIds)
        navigator(dest)
    }
    
    @objc private func audienceTapMicToRequestSeat() {
        guard !roomState.isPKOngoing() else {
            SVProgressHUD.showError(withStatus: "当前 PK 中，无法进行该操作")
            return
        }
        switch roomState.connectState {
        case .request:
            // index -1 代表随机给举手观众一个可用麦位
            requestSeat(index: -1)
        case .waiting:
            navigator(.requestSeatPop(delegate: self))
        case .connecting:
            let seatIndex = self.findSeatIndex()
            guard let seatIndex = seatIndex else { return }
            let seatInfo = self.seatList[seatIndex]
            navigator(.userSeatPop(seatIndex: UInt(seatIndex), isUserMute: roomState.isCloseSelfMic, isSeatMute: seatInfo.isMuted, delegate: self))
        }
    }
    
    func hasNoEmptySeat() -> Bool {
        return self.onSeatUsers.count == seatList.count - 1
    }
    
    func setupRequestStateAndMicOrderListState() {
        RCVoiceRoomEngine.sharedInstance().getRequesterInfoList { [weak self] infos in
            guard let self = self else { return }
            self.requesterInfos = infos
            DispatchQueue.main.async {
                if self.currentUserRole() == .creator  {
                    self.micButton.setBadgeCount(infos.count)
                } else {
                    if infos.map { $0.userId }.contains(Environment.currentUserId) {
                        self.roomState.connectState = .waiting
                    }
                    if self.isSitting() {
                        self.roomState.connectState = .connecting
                    }
                }
            }
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: "获取排麦列表失败")
        }
    }
}

// MARK: - Handle Seat Request Or Invite Delegate
extension VoiceRoomViewController: HandleRequestSeatProtocol {
    func acceptUserRequestSeat(userId: String) {
        if hasNoEmptySeat() {
            SVProgressHUD.showError(withStatus: "麦位已满")
            return
        }
        RCVoiceRoomEngine.sharedInstance().responseRequestSeat(true, userId: userId, content: "") {
            DispatchQueue.main.async {
                self.setupRequestStateAndMicOrderListState()
            }
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: "同意请求失败")
        }
    }
    
    func inviteUserToSeat(userId: String) {
        if isSitting(userId) {
            return SVProgressHUD.showError(withStatus: "用户已经在麦位上了哦")
        }
        if hasNoEmptySeat() {
            SVProgressHUD.showError(withStatus: "麦位已满")
            return
        }
        
        RCVoiceRoomEngine.sharedInstance().sendInvitation(userId, content: "") { invitatonId in 
            SVProgressHUD.showSuccess(withStatus: "已邀请上麦")
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: "邀请连麦发送失败")
        }
    }
}

extension VoiceRoomViewController: RequestSeatPopProtocol {
    func cancelRequestSeatDidClick() {
        RCSensorAction.connectionWithDraw(voiceRoomInfo).trigger()
        RCVoiceRoomEngine.sharedInstance().cancelRequestSeat {
            SVProgressHUD.showSuccess(withStatus: "已撤回连线申请")
            DispatchQueue.main.async {
                self.roomState.connectState = .request
            }
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: "撤回连线申请失败")
        }
    }
}
