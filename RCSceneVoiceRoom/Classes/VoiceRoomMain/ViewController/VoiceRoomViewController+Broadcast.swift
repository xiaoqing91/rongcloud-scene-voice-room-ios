//
//  VoiceRoomViewController+Broadcast.swift
//  RCE
//
//  Created by shaoshuai on 2021/8/20.
//

import UIKit

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupBroadcastModule() {
        setupModules()
        RCBroadcastManager.shared.delegate = self
    }
    
    @_dynamicReplacement(for: handleReceivedMessage(_:))
    private func broadcast_handleReceivedMessage(_ message :RCMessage) {
        handleReceivedMessage(message)
        guard let content = message.content as? RCGiftBroadcastMessage else { return }
        RCBroadcastManager.shared.add(content)
    }
}

extension VoiceRoomViewController: RCRTCBroadcastDelegate {
    
    func broadcastViewAccessible(_ room: RCSceneRoom) -> Bool {
        if room.roomId == voiceRoomInfo.roomId { return false }
        if currentUserRole() == .creator { return false }
        if isSitting() { return false }
        return true
    }
    
    func broadcastViewDidClick(_ room: RCSceneRoom) {
        if room.isPrivate == 1 {
            navigator(.inputPassword(completion: { [weak self] password in
                guard room.password == password else { return }
                self?.roomContainerAction?.switchRoom(room)
            }))
        } else {
            self.roomContainerSwitchRoom(room)
        }
    }
    
    func broadcastViewDidLoad(_ view: RCRTCGiftBroadcastView) {
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(roomInfoView.snp.bottom).offset(8)
            make.height.equalTo(30)
        }
    }
    
    func broadcastViewWillAppear(_ view: RCRTCGiftBroadcastView) {
        view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            view.alpha = 1
        }
    }
}
