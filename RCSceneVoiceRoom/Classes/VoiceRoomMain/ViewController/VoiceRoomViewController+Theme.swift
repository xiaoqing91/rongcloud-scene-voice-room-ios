//
//  VoiceRoomViewController+Theme.swift
//  RCSceneVoiceRoom
//
//  Created by shaoshuai on 2022/5/12.
//

import Kingfisher
import Foundation

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func theme_setupModule() {
        setupModules()
        
        NotificationNameRoomBackgroundUpdated
            .addObserver(self, selector: #selector(onBackgroundChanged(_:)))
        
        let imageURL = URL(string: voiceRoomInfo.backgroundUrl ?? "")
        backgroundImageView.kf.setImage(with: imageURL, options: [.memoryCacheExpiration(.expired)])
    }
    
    @objc
    private func onBackgroundChanged(_ notification: NSNotification) {
        if RCSceneVoiceRoomEnableSwitchableBackgroundImage { return }
        let obj = notification.object as? (String, String)
        let imageURL = URL(string: obj?.1 ?? "")
        backgroundImageView.kf.setImage(with: imageURL, options: [.memoryCacheExpiration(.expired)])
    }
}
