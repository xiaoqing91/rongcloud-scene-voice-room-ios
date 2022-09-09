//
//  VoiceRoomViewController+Setting.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/18.
//

import RCSceneRoom

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
    }
    
    @objc func handleSettingClick() {
        let notice = kvRoomInfo?.extra ?? "欢迎来到\(voiceRoomInfo.roomName)"
        var items: [Item] {
            return [
                .roomLock(voiceRoomInfo.isPrivate == 0),
                .roomName(voiceRoomInfo.roomName),
                .roomNotice(notice),
                .roomBackground,
                .seatFree(!roomState.isFreeEnterSeat),
                .seatMute(!roomState.isMuteAll),
                .seatLock(!roomState.isLockAll),
                .speaker(enable: !roomState.isSilence),
                .seatCount(roomState.isSeatModeLess ? 8 : 4),
                .forbidden(SceneRoomManager.shared.forbiddenWords),
                .music
            ]
        }
        let controller = RCSRSettingViewController(items: items, delegate: self)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overFullScreen
        present(controller, animated: true)
    }
}

extension VoiceRoomViewController: RCSceneRoomSettingProtocol {
    func eventWillTrigger(_ item: Item) -> Bool {
        RCSensorAction.settingClick(voiceRoomInfo, item: item).trigger()
        switch item {
        case .forbidden:
            let roomId = voiceRoomInfo.roomId
            DispatchQueue.main.async {
                self.navigator(.forbiddenList(roomId: roomId))
            }
            return true
        default: return false
        }
    }
    
    func eventDidTrigger(_ item: Item, extra: String?) {
        switch item {
        case .roomLock(let lock):
            setRoomType(isPrivate: lock, password: extra)
        case .roomName(let name):
            roomUpdate(name: name)
        case .roomNotice(let notice):
            noticeDidModified(notice: notice)
        case .roomBackground:
            modifyRoomBackgroundDidClick()
        case .seatFree(let free):
            freeMicDidClick(isFree: free)
        case .seatMute(let mute):
            muteAllSeatDidClick(isMute: mute)
        case .seatLock(let lock):
            lockAllSeatDidClick(isLock: lock)
        case .speaker(let enable):
            silenceSelfDidClick(isSilence: enable)
        case .seatCount(let count):
            lessSeatDidClick(isLess: count == 4)
        case .music:
            presentMusicController()
        default: ()
        }
    }
}

extension VoiceRoomViewController {
    private func setRoomType(isPrivate: Bool, password: String?) {
        let title = isPrivate ? "设置房间密码" : "解锁"
        func onSuccess() {
            SVProgressHUD.showSuccess(withStatus: "已\(title)")
            voiceRoomInfo.isPrivate = isPrivate ? 1 : 0
        }
        func onError() {
            SVProgressHUD.showError(withStatus: title + "失败")
        }
        voiceRoomService.setRoomType(roomId: voiceRoomInfo.roomId,
                                     isPrivate: isPrivate,
                                     password: password) { result in
            switch result {
            case let .success(response):
                guard
                    let model = try? JSONDecoder().decode(RCSceneResponse.self, from: response.data),
                    model.validate()
                else { return onError() }
                onSuccess()
            case .failure: onError()
            }
        }
    }
    
    /// 全麦锁麦
    func muteAllSeatDidClick(isMute: Bool) {
        roomState.isMuteAll = isMute
        
        let currentUserIndex = findSeatIndex() ?? 0
        let range = 0 ... 8
        var seatIndexes = [Int](range)
        seatIndexes.remove(at: currentUserIndex)
        
        let muteIndexes = seatIndexes.map { NSNumber(value: $0) }
        RCVoiceRoomEngine.sharedInstance().muteSeat(muteIndexes, mute: isMute) {
            SVProgressHUD.showSuccess(withStatus: isMute ? "全部麦位已静音" : "已解锁全麦")
        } error: { code, msg in
            SVProgressHUD.showSuccess(withStatus: isMute ? "全部麦位静音失败" : "解锁全麦失败")
        }
    }
    
    /// 全麦锁座
    func lockAllSeatDidClick(isLock: Bool) {
        roomState.isLockAll = isLock
        
        let currentUserIndex = findSeatIndex() ?? 0
        
        let range = 0 ... 8
        var seatIndexes = [Int](range)
        seatIndexes.remove(at: currentUserIndex)
        
        let indexes = seatIndexes.map { NSNumber(value: $0) }
        RCVoiceRoomEngine.sharedInstance().lockSeat(indexes, lock: isLock) {
            SVProgressHUD.showSuccess(withStatus: isLock ? "已锁定全座" : "已解锁全座")
        } error: { code, msg in
            SVProgressHUD.showSuccess(withStatus: isLock ? "锁定全座失败" : "解锁全座失败")
        }
       
    }
    /// 静音
    func silenceSelfDidClick(isSilence: Bool) {
        roomState.isSilence = isSilence
        PlayerImpl.instance.isSilence = isSilence
        RCVoiceRoomEngine.sharedInstance().muteAllRemoteStreams(isSilence)
        SVProgressHUD.showSuccess(withStatus: isSilence ? "扬声器已静音" : "已取消静音")
    }
    /// 音乐
    func musicDidClick() {
        presentMusicController()
    }
    /// 自由上麦
    func freeMicDidClick(isFree: Bool) {
        if let kvRoom = kvRoomInfo {
            kvRoom.isFreeEnterSeat = isFree
            RCVoiceRoomEngine.sharedInstance().setRoomInfo(kvRoom) {
                SVProgressHUD.showSuccess(withStatus: isFree ? "当前观众可自由上麦" : "当前观众上麦要申请")
            } error: { code, msg in
                SVProgressHUD.showError(withStatus: msg)
            }
        }
    }
    /// 房间背景
    func modifyRoomBackgroundDidClick() {
        navigator(.changeBackground(imageList: SceneRoomManager.shared.backgrounds, delegate: self))
    }
    /// 座位数量
    func lessSeatDidClick(isLess: Bool) {
        roomState.isSeatModeLess = isLess
        guard let kvRoom = kvRoomInfo else {
            return
        }
        if isLess {
            kvRoom.seatCount = 5
        } else {
            kvRoom.seatCount = 9
        }
        RCVoiceRoomEngine.sharedInstance().setRoomInfo(kvRoom) {
            let content = RCChatroomSeats()
            content.count = kvRoom.seatCount - 1
            ChatroomSendMessage(content, messageView: self.messageView)
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: msg)
        }
    }
}

extension VoiceRoomViewController: ChangeBackgroundImageProtocol {
    func didConfirmImage(urlSuffix: String) {
        voiceRoomInfo.backgroundUrl = urlSuffix
        NotificationNameRoomBackgroundUpdated.post((voiceRoomInfo.roomId, urlSuffix))
        voiceRoomService.updateRoomBackground(roomId: voiceRoomInfo.roomId, backgroundUrl: urlSuffix) { result in
            switch result.map(RCSceneResponse.self) {
            case let .success(response):
                if response.validate() {
                    SVProgressHUD.showSuccess(withStatus: "更新房间背景成功")
                } else {
                    SVProgressHUD.showError(withStatus: "更新房间背景失败")
                }
            case .failure:
                SVProgressHUD.showError(withStatus: "更新房间背景失败")
            }
        }
        VoiceRoomNotification.backgroundChanged.send(content: urlSuffix)
    }
}

extension VoiceRoomViewController {
    func roomUpdate(name: String) {
        voiceRoomService.setRoomName(roomId: voiceRoomInfo.roomId, name: name) { result in
            switch result.map(RCSceneResponse.self) {
            case let .success(response):
                if response.validate() {
                    SVProgressHUD.showSuccess(withStatus: "更新房间名称成功")
                    if let roomInfo = self.kvRoomInfo {
                        roomInfo.roomName = name
                        RCVoiceRoomEngine.sharedInstance().setRoomInfo(roomInfo) {
                        } error: { code, msg in
                        }
                    }
                } else {
                    SVProgressHUD.showError(withStatus: response.msg ?? "更新房间名称失败")
                }
            case .failure:
                SVProgressHUD.showError(withStatus: "更新房间名称失败")
            }
        }
    }
}
