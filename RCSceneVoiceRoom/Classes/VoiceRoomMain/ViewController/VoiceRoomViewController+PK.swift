//
//  VoiceRoomViewController+PK.swift
//  RCE
//
//  Created by 叶孤城 on 2021/8/9.
//

import SVProgressHUD
import RCVoiceRoomLib
import Combine

enum ClosePKReason {
    case remote
    case myown
    case beginFailed
    case timeEnd
}

enum PKAction {
    case invite
    case reject
    case agree
    case ignore
}

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupChatModule() {
        setupModules()
        pkView.delegate = self
        roomState.pkConnectStateChanged = {
            [weak self] state in
            var image: UIImage?
            switch state {
            case .request:
                image = RCSCAsset.Images.voiceroomPkButton.image
                self?.transitionViewState(isPK: false)
            case .connecting:
                image = RCSCAsset.Images.pkOngoingIcon.image
                self?.transitionViewState(isPK: true)
            case .waiting:
                image = state.image
            }
            self?.pkButton.setImage(image, for: .normal)
        }
        roomState.mutePKStateChanged = {
            [weak self] isMute in
            self?.pkView.setupMuteState(isMute: isMute)
        }
        pkButton.addTarget(self, action: #selector(handlePkButtonClick), for: .touchUpInside)
    }
    
    @_dynamicReplacement(for: handleReceivedMessage(_:))
    private func chat_handleReceivedMessage(_ message :RCMessage) {
        handleReceivedMessage(message)
        /// 同步最新礼物信息
        if let pkGiftMessage = message.content as? RCPKGiftMessage, let content = pkGiftMessage.content {
            pkView.updateGiftValue(content: content, currentRoomId: voiceRoomInfo.roomId)
        }
        /// 同步PK状态
        if let pkStatusContent = message.content as? RCPKStatusMessage, let content = pkStatusContent.content {
            guard let info = self.roomState.currentPKInfo else {
                voiceRoomService.getCurrentPKInfo(roomId: self.voiceRoomInfo.roomId) { [weak self] pkStatus in
                    guard let statusModel = pkStatus, let self = self, statusModel.roomScores.count == 2 else {
                        return
                    }
                    let pkInfo: VoiceRoomPKInfo = {
                        let roomscore1 = statusModel.roomScores[0]
                        let roomscore2 = statusModel.roomScores[1]
                        if roomscore1.leader {
                            return VoiceRoomPKInfo(inviterId: roomscore1.userId, inviteeId: roomscore2.userId, inviterRoomId: roomscore1.roomId, inviteeRoomId: roomscore2.roomId)
                        }
                        return VoiceRoomPKInfo(inviterId: roomscore2.userId, inviteeId: roomscore1.userId, inviterRoomId: roomscore2.roomId, inviteeRoomId: roomscore1.roomId)
                    }()
                    self.roomState.currentPKInfo = pkInfo
                    self.beginPK(pkStatus: statusModel.statusMsg, timeDiff: statusModel.timeDiff, stopPkRoomId: nil, info: pkInfo)
                }
                return
            }
            beginPK(pkStatus: content.statusMsg, timeDiff: content.timeDiff, stopPkRoomId:content.stopPkRoomId, info: info)
        }
    }
    
    private func beginPK(pkStatus: Int, timeDiff: Int, stopPkRoomId: String?, info: VoiceRoomPKInfo) {
        if pkStatus == 0 {
            self.roomState.pkConnectState = .connecting
            
            // 检查之前是否关闭对面PK主播的声音，然后恢复
            if roomState.isMutePKUser {
                RCVoiceRoomEngine.sharedInstance().mutePKUser(false) { result in
                    if result.code == RCVoiceRoomErrorCode.roomSuccess.rawValue {
                        self.roomState.isMutePKUser = false
                    } else {
                        SVProgressHUD.showError(withStatus: "取消静音 PK 失败，请重试")
                    }
                }
            }

            // 打开邀请菜单时，确认同意被其他主播邀请PK后，把邀请菜单关闭
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.pkView.beginPK(info: info, timeDiff: timeDiff/1000, currentRoomOwnerId: self.voiceRoomInfo.userId, currentRoomId: self.voiceRoomInfo.roomId)
         
            forceLockOthers(isLock: true)
        }
        if pkStatus == 1 {
            self.pkView.beginPunishment(passedSeconds: timeDiff/1000, currentRoomOwnerId: self.voiceRoomInfo.userId)
        }
        if pkStatus == 2 {
            self.roomState.pkConnectState = .request

            let reason: ClosePKReason = {
                if let roomID = stopPkRoomId, !roomID.isEmpty {
                    if roomID == voiceRoomInfo.roomId {
                        return .myown
                    } else {
                        return .remote
                    }
                } else {
                    return .timeEnd
                }
            }()
            self.showCloseReasonHud(reason: reason)

            switch info.currentUserRole() {
            case .inviter:
                self.sendTextMessage(text: "本轮PK结束")
                if reason == .timeEnd { //pk自然结束，由邀请者挂断pk
                    RCVoiceRoomEngine.sharedInstance().quitPK { _ in }
                }
            case .invitee:
                self.sendTextMessage(text: "本轮PK结束")
            case .audience:
                ()
            }
            forceLockOthers(isLock: false)
        }
    }
    
    @objc private func handlePkButtonClick() {
        RCSensorAction.PKClick(voiceRoomInfo).trigger()
        switch roomState.pkConnectState {
        case .connecting:
            showClosePKAlert()
        case .request:
            navigator(.onlineRooms(selectingUserId: roomState.lastInviteUserId, delegate: self))
        case .waiting:
            guard let userId = roomState.lastInviteUserId, let roomId = roomState.lastInviteRoomId else {
                return
            }
            showCancelPKAlert(roomId: roomId, userId: userId)
        }
    }
    
    private func showPKInvite(roomId: String, userId: String) {
        let vc = UIAlertController(title: "是否接受PK邀请(10)", message: nil, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "同意", style: .default, handler: { _ in
            RCVoiceRoomEngine.sharedInstance().responsePKInvitation(roomId, inviter: userId, accept: true) { _ in }
        }))
        vc.addAction(UIAlertAction(title: "拒绝", style: .cancel, handler: { _ in
            SVProgressHUD.showSuccess(withStatus: "已拒绝 PK 邀请")
            RCVoiceRoomEngine.sharedInstance().responsePKInvitation(roomId, inviter: userId, accept: false) { _ in }
        }))

        UIApplication.shared.topmostController()?.present(vc, animated: true, completion: {
            self.inviterCount = 10
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {
                [weak self] currentTimer in
                self?.inviteTimerDidCountdown(inviterRoomId: roomId, inviterId: userId)
            })
            RunLoop.main.add(self.timer!, forMode: .common)
        })
    }
    
    @objc func inviteTimerDidCountdown(inviterRoomId: String, inviterId: String) {
        inviterCount -= 1
        guard let alertController = UIApplication.shared.topmostController() as? UIAlertController else {
            timer?.invalidate()
            return
        }
        guard inviterCount > 0 else {
            timer?.invalidate()
            return
        }
        alertController.title = "是否接受PK邀请(\(inviterCount))"
    }
    
    private func showClosePKAlert() {
        let vc = UIAlertController(title: "挂断并结束本轮 PK 么？", message: nil, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "同意", style: .default, handler: { _ in
            self.quitPKConnectAndNotifyServer()
        }))
        vc.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { _ in
            
        }))
        present(vc, animated: true, completion: nil)
    }
    
    private func showCancelPKAlert(roomId: String, userId: String) {
        let actions = [
            ActionDependency(action: {
                self.cancelPK(userId: userId, roomId: roomId)
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }, name: "撤回邀请"),
            ActionDependency(action: {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }, name: "取消")]
        let vc = OptionsViewController(dependency: PresentOptionDependency(title: "已发起PK邀请", actions: actions))
        topmostController().present(vc, animated: true)
    }
    
    private func sendTextMessage(text: String) {
        let textMessage = RCTextMessage()
        textMessage.content = text
        ChatroomSendMessage(textMessage) { result in
            switch result {
            case let .success(mid):
                DispatchQueue.main.async {
                    self.messageView.addMessage(textMessage)
                }
            case .failure(_): break
            }
        }
    }
    /// RTC 已建立连接，向服务端请求PK开始
    private func sendPKRequest() {
        guard let info = roomState.currentPKInfo else {
            return
        }
        if let vc = presentedViewController as? OptionsViewController {
            vc.dismiss(animated: true, completion: nil)
        }
        let role = info.currentUserRole()
        switch role {
        case .inviter:
            forceLockOthers(isLock: true)
            sendAttendPKMessage(pkInfo: info)
            voiceRoomService.setPKStatus(roomId: info.inviterRoomId, toRoomId: info.inviteeRoomId, status: .begin) { isSuccess in
                if !isSuccess {
                    self.quitPKConnectAndNotifyServer()
                }
            }
        case .invitee:
            forceLockOthers(isLock: true)
            sendAttendPKMessage(pkInfo: info)
        case .audience:
            ()
        }
    }
    
    private func forceLockOthers(isLock: Bool) {
        if self.currentUserRole() == .creator {
            RCVoiceRoomEngine.sharedInstance().lockOtherSeats(isLock)
        }
    }
    
    func getPKStatus() {
        /// 获取服务器PK最新信息
        voiceRoomService.getCurrentPKInfo(roomId: self.voiceRoomInfo.roomId) { [weak self] pkStatus in
            guard let statusModel = pkStatus, let self = self, statusModel.roomScores.count == 2 else {
                return
            }
            let pkInfo: VoiceRoomPKInfo = {
                let roomscore1 = statusModel.roomScores[0]
                let roomscore2 = statusModel.roomScores[1]
                if roomscore1.leader {
                    return VoiceRoomPKInfo(inviterId: roomscore1.userId, inviteeId: roomscore2.userId, inviterRoomId: roomscore1.roomId, inviteeRoomId: roomscore2.roomId)
                }
                return VoiceRoomPKInfo(inviterId: roomscore2.userId, inviteeId: roomscore1.userId, inviterRoomId: roomscore2.roomId, inviteeRoomId: roomscore1.roomId)
            }()
            self.roomState.currentPKInfo = pkInfo
            switch statusModel.statusMsg {
            case 0:
                self.roomState.pkConnectState = .connecting
                self.pkView.beginPK(info: pkInfo, timeDiff: statusModel.seconds, currentRoomOwnerId: self.voiceRoomInfo.userId, currentRoomId: self.voiceRoomInfo.roomId)
                if pkInfo.currentUserRole() != .audience {
                    self.resumePK()
                }
                self.pkView.updateGiftValue(content: PKGiftModel(roomScores: statusModel.roomScores), currentRoomId: self.voiceRoomInfo.roomId)
            case 1:
                self.roomState.pkConnectState = .connecting
                self.pkView.beginPunishment(passedSeconds: statusModel.seconds, info: pkInfo, currentRoomOwnerId: self.voiceRoomInfo.userId)
                if pkInfo.currentUserRole() != .audience {
                    self.resumePK()
                }
                self.pkView.updateGiftValue(content: PKGiftModel(roomScores: statusModel.roomScores), currentRoomId: self.voiceRoomInfo.roomId)
            default:
                self.roomState.pkConnectState = .request
            }
        }
    }
    
    private func resumePK() {
        guard let pkInfo = roomState.currentPKInfo, pkInfo.currentUserRole() != .audience else {
            return
        }
        RCVoiceRoomEngine.sharedInstance().resumePK(with: RCVoicePKInfo(inviterId: pkInfo.inviterId, inviterRoomId: pkInfo.inviterRoomId, inviteeId: pkInfo.inviteeId, inviteeRoomId: pkInfo.inviteeRoomId)) { result in
            if result.code == RCVoiceRoomErrorCode.roomSuccess.rawValue {
                SVProgressHUD.showSuccess(withStatus: "恢复PK成功")
            } else {
                SVProgressHUD.showError(withStatus: "恢复PK 失败")
            }
        }
    }
    
    private func sendAttendPKMessage(pkInfo: VoiceRoomPKInfo) {
        var lookUpUserId = ""
        if voiceRoomInfo.roomId == pkInfo.inviterRoomId {
            lookUpUserId = pkInfo.inviteeId
        } else if voiceRoomInfo.roomId == pkInfo.inviteeRoomId {
            lookUpUserId = pkInfo.inviterId
        }
        RCSceneUserManager.shared.fetch([lookUpUserId]) { list in
            guard let user = list.first else {
                return
            }
            self.sendTextMessage(text: "与 \(user.userName) 的 PK 即将开始，PK过程中，麦上观众将被抱下麦")
        }
    }
    
    private func quitPKConnectAndNotifyServer() {
        guard let info = roomState.currentPKInfo else {
            return
        }
        RCVoiceRoomEngine.sharedInstance().quitPK { result in
            if result.code == RCVoiceRoomErrorCode.roomSuccess.rawValue {
                SVProgressHUD.showSuccess(withStatus: "退出PK成功")
            } else {
                SVProgressHUD.showError(withStatus: "退出PK失败")
            }
        }
        let roomId = voiceRoomInfo.roomId == info.inviterRoomId ? info.inviterRoomId : info.inviteeRoomId
        let toRoomId = voiceRoomInfo.roomId == info.inviterRoomId ? info.inviteeRoomId : info.inviterRoomId
        voiceRoomService.setPKStatus(roomId:roomId, toRoomId: toRoomId, status: .close)
    }
    
    private func showCloseReasonHud(reason: ClosePKReason) {
        switch reason {
        case .remote:
            SVProgressHUD.showSuccess(withStatus: "对方挂断，本轮PK结束")
        case .timeEnd:
            SVProgressHUD.showSuccess(withStatus: "本轮PK结束")
        case .myown:
            SVProgressHUD.showSuccess(withStatus: "我方挂断，本轮PK结束")
        case .beginFailed:
            SVProgressHUD.showError(withStatus: "开始PK失败，请重试")
        }
    }
    
    private func cancelPK(userId: String, roomId: String) {
        guard roomState.pkConnectState == .waiting else {
            return
        }
        RCVoiceRoomEngine.sharedInstance().cancelPKInvitation(roomId, invitee: userId) {
            self.roomState.pkConnectState = .request
            SVProgressHUD.showSuccess(withStatus: "已取消邀请")
        } error: { _, _ in
            SVProgressHUD.showError(withStatus: "撤回PK邀请失败，请重试")
        }
    }
    
    private func transitionViewState(isPK: Bool) {
        pkView.reset()
        if isPK {
            messageView.snp.remakeConstraints { make in
                make.bottom.equalTo(toolBarView.snp.top).offset(-8.resize)
                make.left.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(278.0 / 375)
                make.top.equalTo(pkView.snp.bottom).offset(20)
            }
            UIView.animate(withDuration: 0.3) {
                self.ownerView.alpha = 0
                self.collectionView.alpha = 0
                self.pkView.alpha = 1
                self.view.layoutIfNeeded()
            }
        } else {
            messageView.snp.remakeConstraints {
                $0.left.equalToSuperview()
                $0.width.equalToSuperview().multipliedBy(278.0 / 375)
                $0.bottom.equalTo(toolBarView.snp.top).offset(-8.resize)
                $0.top.equalTo(collectionView.snp.bottom).offset(21.resize)
            }
            UIView.animate(withDuration: 0.3) {
                self.ownerView.alpha = 1
                self.collectionView.alpha = 1
                self.pkView.alpha = 0
                self.view.layoutIfNeeded()
            }
            DispatchQueue.main.async {
                let size = self.messageView.tableView.contentSize
                self.messageView.tableView.scrollRectToVisible(CGRect(origin: .zero, size: size), animated: true)
            }
        }
        
    }
}

extension VoiceRoomViewController {
    func pkInvitationDidReceive(fromRoom inviterRoomId: String, byUser inviterUserId: String) {
        showPKInvite(roomId: inviterRoomId, userId: inviterUserId)
    }
    
    func pkOngoing(withInviterRoom inviterRoomId: String, withInviterUserId inviterUserId: String, withInviteeRoom inviteeRoomId: String, withInviteeUserId inviteeUserId: String) {
        roomState.currentPKInfo = VoiceRoomPKInfo(inviterId: inviterUserId, inviteeId: inviteeUserId, inviterRoomId: inviterRoomId, inviteeRoomId: inviteeRoomId)
        sendPKRequest()
    }
    
    func cancelPKInvitationDidReceive(fromRoom inviterRoomId: String, byUser inviterUserId: String) {
        if let presentVC = presentedViewController, presentVC.isKind(of: UIAlertController.self) {
            presentVC.dismiss(animated: true, completion: nil)
        }
        SVProgressHUD.showError(withStatus: "邀请已被取消")
    }
    
    func rejectPKInvitationDidReceive(fromRoom inviteeRoomId: String, byUser initeeUserId: String) {
        SVProgressHUD.showError(withStatus: "对方拒绝了您的PK邀请")
        self.roomState.pkConnectState = .request
    }
    
    func ignorePKInvitationDidReceive(fromRoom inviteeRoomId: String, byUser inviteeUserId: String) {
        SVProgressHUD.showError(withStatus: "对方无回应，PK发起失败")
        self.roomState.pkConnectState = .request
    }

    func pkDidFinish() {
        self.roomState.pkConnectState = .request
        forceLockOthers(isLock: false)
    }
}

extension VoiceRoomViewController: OnlineRoomCreatorDelegate {
    func selectedUserDidClick(userId: String, from roomId: String) {
        showCancelPKAlert(roomId: roomId, userId: userId)
    }
    
    func userDidInvite(userId: String, from roomId: String) {
        voiceRoomService.isPK(roomId: roomId) { result in
            switch result {
            case .success(let response):
                guard let status = try? JSONDecoder().decode(RCSceneWrapper<Bool>.self, from: response.data),
                        status.data == false
                else {
                    return SVProgressHUD.showError(withStatus: "对方正在PK中")
                }
                RCVoiceRoomEngine.sharedInstance().sendPKInvitation(roomId, invitee: userId) {
                    self.roomState.pkConnectState = .waiting
                    self.roomState.lastInviteRoomId = roomId
                    self.roomState.lastInviteUserId = userId
                } error: { _, _ in
                    SVProgressHUD.showError(withStatus: "邀请PK失败")
                }

            case .failure(_):
                SVProgressHUD.showError(withStatus: "对方正在PK中")
            }
        }
    }
}

extension VoiceRoomViewController: VoiceRoomPKViewDelegate {
    func generatePkResult(twoSides: (PKResult, PKResult)) {
        let sendClosure = {
            var msg = "平局"
            if twoSides.0 == .win {
                msg = "我方胜利"
            } else if twoSides.0 == .lose {
                msg = "我方失败"
            }
            self.sendTextMessage(text: msg)
        }
        guard let info = roomState.currentPKInfo else {
            return
        }
        switch info.currentUserRole() {
        case .inviter, .invitee:
            sendClosure()
        case .audience:
            ()
        }
    }
    
    func silenceButtonDidClick() {
        let isMute = !roomState.isMutePKUser
        let message = isMute ? "静音" : "取消静音"
        RCVoiceRoomEngine.sharedInstance().mutePKUser(isMute) { [weak self] result in
            if result.code == RCVoiceRoomErrorCode.roomSuccess.rawValue {
                self?.roomState.isMutePKUser.toggle()
                SVProgressHUD.showSuccess(withStatus: "\(message) PK 成功")
            } else {
                SVProgressHUD.showError(withStatus: "\(message) PK 失败，请重试")
            }
        }
    }
}
