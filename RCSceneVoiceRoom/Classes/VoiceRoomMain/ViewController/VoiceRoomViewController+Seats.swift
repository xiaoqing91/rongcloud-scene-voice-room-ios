//
//  VoiceRoomViewController+Seats.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/18.
//

import SVProgressHUD

extension VoiceRoomViewController {
    @_dynamicReplacement(for: managers)
    private var seats_managers: [RCSceneRoomUser] {
        get { managers }
        set {
            managers = newValue
            SceneRoomManager.shared.managers = managers.map(\.userId)
            messageView.tableView.reloadData()
            collectionView.reloadData()
        }
    }
    
    @_dynamicReplacement(for: userGiftInfo)
    var seats_userGiftInfo: [String: Int] {
        get {
            return userGiftInfo
        }
        set {
            userGiftInfo = newValue
            collectionView.reloadData()
            ownerView.updateGiftVales(giftValues: userGiftInfo)
        }
    }
    
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func updateCollectionViewHeight() {
        let height = collectionView.contentSize.height
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(height + 20)
        }
        view.layoutIfNeeded()
    }
}

extension VoiceRoomViewController {

    func updateChangesWithSeatUser() {
        /// 当麦位数量变化时，触发连麦用户下麦，需要更新状态
        if roomState.connectState == .connecting {
            roomState.connectState = isSitting() ? .connecting : .request
        } else if isSitting() {
            micButton.micState = voiceRoomInfo.isOwner ? .user : .connecting
        }
        if let seatInfo = seatList.first {
            ownerView.updateOwner(seatInfo: seatInfo)
            ownerView.updateGiftVales(giftValues: userGiftInfo)
        }
        collectionView.reloadData()
    }
    
    func requestSeat(index: Int) {
        if roomState.connectState == .waiting {
            navigator(.requestSeatPop(delegate: self))
            return
        }
        guard roomState.connectState == .request else {
            return
        }
        RCSensorAction.connectRequest(voiceRoomInfo).trigger()
        
        if roomState.isFreeEnterSeat {
            return enterSeatIfAvailable()
        }
        
        RCVoiceRoomEngine.sharedInstance()
            .requestSeat(index, content: "") { [weak self] result in
                DispatchQueue.main.async {
                    if result.code == RCVoiceRoomErrorCode.roomSuccess.rawValue {
                        SVProgressHUD.showSuccess(withStatus: "已申请连线，等待房主接受")
                        self?.roomState.connectState = .waiting
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "申请连线失败")
                    }
                }
            }
    }
    
    func enterSeatIfAvailable(_ isPicked: Bool = false) {
//        RCVoiceRoomEngine.sharedInstance().cancelRequestSeat {} error: { code, msg in }
        var canEnter = false
        for seatIndex in Array(1..<self.seatList.count) {
            if self.onSeatUsers.firstIndex { $0.seatIndex == seatIndex } == nil {
                canEnter = true
                enterSeat(index: seatIndex, isPicked)
                break
            }
        }
        if !canEnter {
            SVProgressHUD.showError(withStatus: "没有空座了，请稍后重试")
        }
    }
    
    typealias EnterSeatCompletion = () -> Void
    func enterSeat(index: Int, _ isPicked: Bool = false, completion: EnterSeatCompletion? = nil) {
        if roomState.isEnterSeatWaiting { return }
        roomState.isEnterSeatWaiting.toggle()
        RCVoiceRoomEngine.sharedInstance()
            .enterSeat(UInt(index)) { [weak self] in
                self?.roomState.isEnterSeatWaiting.toggle()
                DispatchQueue.main.async {
                    if !isPicked {
                        SVProgressHUD.showInfo(withStatus: "上麦成功")
                    }
                    self?.roomState.connectState = .connecting
                    self?.roomContainerAction?.disableSwitchRoom()
                    completion?()
                }
            } error: { [weak self] code, msg in
                self?.roomState.isEnterSeatWaiting.toggle()
                debugPrint("enter seat error \(msg)")
                completion?()
            }
    }
    
    func leaveSeat(isKickout: Bool = false) {
        RCSensorAction.connectionWithDraw(voiceRoomInfo).trigger()
        RCVoiceRoomEngine.sharedInstance().leaveSeat {
            [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                if !isKickout {
                    SVProgressHUD.showSuccess(withStatus: "下麦成功")
                } else {
                    SVProgressHUD.showSuccess(withStatus: "您已被抱下麦")
                }
                if !(self.currentUserRole() == .creator) {
                    self.roomState.connectState = .request
                    self.roomContainerAction?.enableSwitchRoom()
                }
                RCSceneMusic.stop()
            }
        } error: { code, msg in
            debugPrint("下麦失败\(code) \(msg)")
        }
    }
    
    func isSitting(_ userId: String = Environment.currentUserId) -> Bool {
        return self.onSeatUsers.contains { $0.userId == userId }
    }
    
    func findSeatIndex(of userId: String = Environment.currentUserId) -> Int? {
        let firstIndex = self.onSeatUsers.firstIndex { $0.userId == userId }
        if let firstIndex = firstIndex {
            return self.onSeatUsers[firstIndex].seatIndex
        } else {
            return nil
        }
    }
}

//MARK: - Seat CollectionView DataSource
extension VoiceRoomViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return seatList.count - 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: VoiceRoomSeatCollectionViewCell.self)
        let seatIndex = indexPath.row + 1
        cell.update(seatInfo: seatList[seatIndex],
                    index: seatIndex,
                    managers: managers,
                    giftValues: userGiftInfo)
        return cell
    }
}

extension VoiceRoomViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let seatIndex = indexPath.row + 1
        
        let seatInfo = self.seatList[seatIndex]
                
        var user: RCVoiceUserInfo? = nil
        let firstIndex = self.onSeatUsers.firstIndex { $0.seatIndex == seatIndex }
        if let firstIndex = firstIndex {
            user = self.onSeatUsers[firstIndex]
        }
        
        if let seatUser = user {
            if seatUser.userId == Environment.currentUserId {
                let seatInfo = self.seatList[seatIndex]
                navigator(.userSeatPop(seatIndex: UInt(seatIndex), isUserMute: roomState.isCloseSelfMic, isSeatMute: seatInfo.isMuted, delegate: self))
            } else {
                operate(seatUser.userId)
            }
        } else {
            if currentUserRole() == .creator {
                navigator(.ownerClickEmptySeat(seatInfo, UInt(seatIndex), self))
            } else {
                if isSitting() {
                    if roomState.isEnterSeatWaiting { return }
                    roomState.isEnterSeatWaiting.toggle()
                    RCVoiceRoomEngine.sharedInstance().switchSeat(to: UInt(seatIndex)) {
                        [weak self] in
                        guard let self = self else { return }
                        self.roomState.isEnterSeatWaiting.toggle()
                        self.roomState.connectState = .connecting
                        guard !seatInfo.isMuted else { return }
                    } error: { [weak self] code, msg in
                        self?.roomState.isEnterSeatWaiting.toggle()
                    }
                } else {
                    if roomState.isFreeEnterSeat {
                        enterSeat(index: seatIndex)
                    } else {
                        requestSeat(index: seatIndex)
                    }
                }
            }
        }
        if seatInfo.isLocked {
            if currentUserRole() == .creator {
                navigator(.ownerClickEmptySeat(seatInfo, UInt(seatIndex), self))
            } else {
                if isSitting() {
                    SVProgressHUD.showError(withStatus: "该座位已经被锁定")
                }
            }
        }
    }
}

extension VoiceRoomViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let width = collectionView.bounds.width - collectionView.contentInset.left * 2
        return floor((width - 70 * 4) / 3.0)
    }
}
