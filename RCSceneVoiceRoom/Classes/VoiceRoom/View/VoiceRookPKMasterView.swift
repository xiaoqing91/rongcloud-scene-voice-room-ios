//
//  VoiceRookPKMasterView.swift
//  RCE
//
//  Created by 叶孤城 on 2021/8/23.
//

import UIKit
import RCSceneService

class VoiceRookPKMasterView: UIView {
    private lazy var avatarImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFill
        instance.clipsToBounds = true
        instance.layer.cornerRadius = 34.resize
        instance.image = RCSCAsset.Images.defaultAvatar.image
        return instance
    }()
    private lazy var borderImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFill
        instance.image = RCSCAsset.Images.gradientBorder.image
        return instance
    }()
    private lazy var pkCrownImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = RCSCAsset.Images.pkCrownIcon.image
        instance.isHidden = true
        return instance
    }()
    private lazy var pkBottomImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = nil
        instance.isHidden = true
        return instance
    }()
    private lazy var nameLabel: UILabel = {
        let instance = UILabel()
        instance.font = .systemFont(ofSize: 14)
        instance.textColor = .white
        return instance
    }()
    private lazy var muteMicrophoneImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = RCSCAsset.Images.muteMicrophoneIcon.image
        instance.isHidden = true
        return instance
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(avatarImageView)
        addSubview(borderImageView)
        addSubview(nameLabel)
        addSubview(muteMicrophoneImageView)
        addSubview(pkCrownImageView)
        addSubview(pkBottomImageView)
        
        avatarImageView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 68.resize, height: 68.resize))
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
            $0.bottom.equalToSuperview()
            $0.width.lessThanOrEqualTo(150)
        }
        
        pkBottomImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(avatarImageView.snp.bottom).offset(10)
        }
        
        pkCrownImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(avatarImageView.snp.top).offset(7)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateUser(_ user: RCSceneRoomUser) {
        avatarImageView.kf.setImage(with: URL(string: user.portraitUrl), placeholder: RCSCAsset.Images.defaultAvatar.image)
        nameLabel.text = user.userName
    }
    
    func updatePKResult(result: PKResult) {
        switch result {
        case .win:
            pkCrownImageView.isHidden = false
            pkBottomImageView.isHidden = false
            pkBottomImageView.image = RCSCAsset.Images.pkWinningIcon.image
        case .lose:
            pkCrownImageView.isHidden = true
            pkBottomImageView.isHidden = false
            pkBottomImageView.image = RCSCAsset.Images.pkFailedIcon.image
        case .tie:
            pkCrownImageView.isHidden = true
            pkBottomImageView.isHidden = true
        }
    }
    
    func reset() {
        pkCrownImageView.isHidden = true
        pkBottomImageView.isHidden = true
    }
}
