//
//  VoiceRoomOwnerSeatView.swift
//  RCE
//
//  Created by 叶孤城 on 2021/4/25.
//

import Pulsator
import SwiftUI


extension RCVoiceSeatInfo {
    var radarDisable: Bool {
        return seatUser == nil
    }
}

protocol VoiceRoomMasterViewProtocol: AnyObject {
    func masterViewDidClick()
}

class VoiceRoomMasterView: UIView {
    weak var delegate: VoiceRoomMasterViewProtocol?
    private lazy var radarView: Pulsator = {
        let instance = Pulsator()
        instance.numPulse = 4
        instance.radius = 80.resize
        instance.animationDuration = 1.5
        instance.backgroundColor = UIColor(hexString: "#FF69FD").cgColor
        return instance
    }()
    private lazy var avatarImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFill
        instance.clipsToBounds = true
        instance.layer.cornerRadius = 40.resize
        instance.image = RCSCAsset.Images.emptySeatUserAvatar.image
        return instance
    }()
    private lazy var borderImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFill
        instance.image = RCSCAsset.Images.gradientBorder.image
        return instance
    }()
    private lazy var nameLabel: UILabel = {
        let instance = UILabel()
        instance.font = .systemFont(ofSize: 14)
        instance.textColor = .white
        return instance
    }()
    private lazy var giftView: GiftValueView = {
        let instance = GiftValueView(frame: .zero)
        return instance
    }()
    private lazy var muteMicrophoneImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = RCSCAsset.Images.muteMicrophoneIcon.image
        instance.isHidden = true
        return instance
    }()
    private var lastBeginAnimation = Date().timeIntervalSince1970
    private(set) var seatInfo: RCVoiceSeatInfo?
    
    var giftValue: Int {
        return giftView.value
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(radarView)
        addSubview(avatarImageView)
        addSubview(borderImageView)
        addSubview(nameLabel)
        addSubview(giftView)
        addSubview(muteMicrophoneImageView)
        avatarImageView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 80.resize, height: 80.resize))
            $0.top.left.right.equalToSuperview().inset(2)
        }
        
        borderImageView.snp.makeConstraints { make in
            make.edges.equalTo(avatarImageView)
        }
        
        muteMicrophoneImageView.snp.makeConstraints {
            $0.right.bottom.equalTo(avatarImageView)
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarImageView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
        
        giftView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.bottom.equalToSuperview()
        }
        
        isUserInteractionEnabled = true
        let ownerTap = UITapGestureRecognizer(target: self, action: #selector(handleUserTap))
        addGestureRecognizer(ownerTap)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        radarView.position = avatarImageView.center
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleUserTap() {
        delegate?.masterViewDidClick()
    }
    
    func updateOwner(seatInfo: RCVoiceSeatInfo) {
        self.seatInfo = seatInfo
        radarView.isHidden = seatInfo.radarDisable

        if let seatUser = seatInfo.seatUser {
            RCSceneUserManager.shared.fetchUserInfo(userId: seatUser.userId) { [weak self] user in
                if user.portraitUrl.isEmpty {
                    self?.avatarImageView.image = RCSCAsset.Images.defaultAvatar.image
                } else {
                    self?.avatarImageView.kf.setImage(with: URL(string: user.portraitUrl), placeholder: RCSCAsset.Images.defaultAvatar.image)
                }
                self?.nameLabel.text = user.userName
            }
            borderImageView.isHidden = false
            muteMicrophoneImageView.isHidden = !seatUser.disableMic
        } else {
            borderImageView.isHidden = true
            muteMicrophoneImageView.isHidden = true
            self.avatarImageView.image = RCSCAsset.Images.emptySeatUserAvatar.image
            self.nameLabel.text = " "
        }
    }
    
    func updateGiftVales(giftValues: [String: Int]) {
        if let seatUser = seatInfo?.seatUser {
            self.giftView.update(value: giftValues[seatUser.userId] ?? 0)
        } else {
            self.giftView.update(value: 0)
        }
    }
    
    func setSpeakingState(isSpeaking: Bool) {
        let isMuted = seatInfo?.isMuted ?? true
        let haveUser = seatInfo?.seatUser != nil
        guard isSpeaking, haveUser, !isMuted else {
            self.radarView.stop()
            return
        }
        if radarView.isPulsating {
            return
        } else {
            radarView.start()
            lastBeginAnimation = Date().timeIntervalSince1970
        }
    }
    
    func hideGiftView(isHidden: Bool) {
        giftView.isHidden = isHidden
    }
    
    func updateUser(_ user: RCSceneRoomUser) {
        avatarImageView.kf.setImage(with: URL(string: user.portraitUrl), placeholder: RCSCAsset.Images.defaultAvatar.image)
        nameLabel.text = user.userName
    }
}
