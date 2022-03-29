//
//  VoiceRoom+Extension.swift
//  RCSceneVoiceRoom
//
//  Created by shaoshuai on 2022/2/24.
//

import RCSceneService

extension RCSceneRoom {
    var switchable: Bool {
        return isPrivate == 0 && userId != Environment.currentUserId
    }
    
    var isOwner: Bool {
        return userId == Environment.currentUserId
    }
}

extension RCSceneRoomUser {
    var rcUser: RCUserInfo {
        return RCUserInfo(userId: userId, name: userName, portrait: portraitUrl)
    }
}
