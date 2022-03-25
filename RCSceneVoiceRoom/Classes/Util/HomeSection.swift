//
//  HomeSection.swift
//  RCE
//
//  Created by 叶孤城 on 2021/4/19.
//

import UIKit

extension HomeItem {
    var image: UIImage? {
        switch self {
        case .audioRoom:
            return RCSCAsset.Images.voiceRoomBackground.image
        case .videoCall:
            return RCSCAsset.Images.videoLiveRoomBackground.image
        case .audioCall:
            return RCSCAsset.Images.voiceCallRoomBackground.image
        case .radioRoom:
            return RCSCAsset.Images.homeRadioRoom.image
        case .liveVideo:
            return RCSCAsset.Images.liveVideoHomeBg.image
        }
    }
    
    var enabled: Bool {
        return true
    }
}
