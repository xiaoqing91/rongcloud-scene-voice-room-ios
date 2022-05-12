//
//  VoiceRoomViewController+Theme.swift
//  RCSceneVoiceRoom
//
//  Created by shaoshuai on 2022/5/12.
//

import Kingfisher

extension VoiceRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func theme_setupModule() {
        setupModules()
        
        NotificationNameRoomBackgroundUpdated
            .addObserver(self, selector: #selector(onBackgroundChanged))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.onBackgroundChanged()
        }
    }
    
    @objc
    private func onBackgroundChanged() {
        if RCSceneVoiceRoomEnableSwitchableBackgroundImage { return }
        let imageURL = URL(string: voiceRoomInfo.backgroundUrl ?? "")
        backgroundImageView.kf.setImage(with: imageURL, options: [.memoryCacheExpiration(.expired)])
    }
}
