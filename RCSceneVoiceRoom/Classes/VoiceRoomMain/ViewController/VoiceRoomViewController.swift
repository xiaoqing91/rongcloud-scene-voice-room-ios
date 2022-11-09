//
//  VoiceRoomViewController.swift
//  RCE
//
//  Created by 叶孤城 on 2021/4/20.
//

import Kingfisher
import RCSceneRoom

let alertTypeVideoAlreadyClose = "alertTypeVideoAlreadyClose"
let alertTypeConfirmCloseRoom = "alertTypeConfirmCloseRoom"

struct managersWrapper: Codable {
    let code: Int
    let data: [RCSceneRoomUser]?
}

class VoiceRoomViewController: UIViewController {
    weak var roomContainerAction: RCRoomContainerAction?
    dynamic var kvRoomInfo: RCVoiceRoomInfo?
    dynamic var voiceRoomInfo: RCSceneRoom
    dynamic var seatList: [RCVoiceSeatInfo] = {
        var list = [RCVoiceSeatInfo]()
        for _ in 0...8 {
            list.append(RCVoiceSeatInfo())
        }
        return list
    }()
    dynamic var managers = [RCSceneRoomUser]()
    dynamic var userGiftInfo = [String: Int]()
    dynamic var roomState: RoomSettingState
    dynamic var isRoomClosed = false
    dynamic var timer: Timer?
    dynamic var inviterCount: Int = 10
    
    var roomUsers = Set<String>()

    private(set) lazy var roomNoticeView = SceneRoomNoticeView()
    private(set) lazy var roomInfoView = SceneRoomInfoView(voiceRoomInfo)
    private(set) lazy var moreButton = UIButton()
    private(set) lazy var ownerView = VoiceRoomMasterView()
    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        let instance = UICollectionView(frame: .zero, collectionViewLayout: layout)
        instance.register(cellType: VoiceRoomSeatCollectionViewCell.self)
        instance.backgroundColor = .clear
        instance.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        instance.isScrollEnabled = false
        instance.showsVerticalScrollIndicator = false
        return instance
    }()
    private(set) lazy var backgroundImageView: AnimatedImageView = {
        let instance = AnimatedImageView()
        instance.contentMode = .scaleAspectFill
        instance.clipsToBounds = true
        instance.runLoopMode = .default
        return instance
    }()
    
    private(set) lazy var chatroomView = RCChatroomSceneView()
    private(set) lazy var pkButton = RCChatroomSceneButton(.pk)
    private(set) lazy var micButton = RCChatroomSceneButton(.mic)
    private(set) lazy var giftButton = RCChatroomSceneButton(.gift)
    private(set) lazy var messageButton = RCChatroomSceneButton(.message)
    private(set) lazy var settingButton = RCChatroomSceneButton(.setting)
    
    var messageView: RCChatroomSceneMessageView {
        return chatroomView.messageView
    }
    var toolBarView: RCChatroomSceneToolBar {
        return chatroomView.toolBar
    }
    
    lazy var pkView = VoiceRoomPKView()
    
    private let musicInfoBubbleView = RCMusicEngine.musicInfoBubbleView
    
    private let isCreate: Bool
    
    var floatingManager: RCSceneRoomFloatingProtocol?
    
    var requesterInfos = [RCSRequester]()
    var onSeatUsers = [RCVoiceUserInfo]()
    
    init(roomInfo: RCSceneRoom, isCreate: Bool = false) {
        voiceRoomInfo = roomInfo
        self.isCreate = isCreate
        roomState = RoomSettingState(room: roomInfo)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
        RCVoiceRoomEngine.sharedInstance().version2Compatible = true
        RCVoiceRoomEngine.sharedInstance().setDelegate(self)
        /**TO BE FIX 后续用新的router替换*/
        Router.default.setupAppNavigation(appNavigation: RCAppNavigation())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("voice room deinit")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVoiceRoom()
        buildLayout()
        setupModules()
        addObserver()
        bubbleViewAddGesture()
        UserDefaults.standard.increaseFeedbackCountdown()
        RCIM.shared().addReceiveMessageDelegate(self)
        RCSceneMusic.join(voiceRoomInfo, bubbleView: musicInfoBubbleView!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if parent == nil {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
        fetchManagers()
        messageButton.refreshMessageCount()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if parent == nil {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    func roomContainerSwitchRoom(_ room: RCSceneRoom) {
        self.roomContainerAction?.switchRoom(room)
    }
    
    private func buildLayout() {
        view.backgroundColor = .clear
        pkView.alpha = 0
        view.addSubview(backgroundImageView)
        view.addSubview(messageView)
        view.addSubview(ownerView)
        view.addSubview(roomInfoView)
        view.addSubview(collectionView)
        view.addSubview(moreButton)
        view.addSubview(toolBarView)
        view.addSubview(roomNoticeView)
        view.addSubview(pkView)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        messageView.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(278.0 / 375)
            $0.bottom.equalTo(toolBarView.snp.top).offset(-8.resize)
            $0.top.equalTo(collectionView.snp.bottom).offset(21.resize)
        }
        
        roomInfoView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(9)
            $0.left.equalToSuperview()
        }
        
        roomNoticeView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.top.equalTo(roomInfoView.snp.bottom).offset(12)
        }
        
        ownerView.snp.makeConstraints {
            $0.top.equalTo(roomInfoView.snp.bottom).offset(14.resize)
            $0.centerX.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(ownerView.snp.bottom).offset(20.resize)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(230)
        }
        
        moreButton.snp.makeConstraints {
            $0.centerY.equalTo(roomInfoView)
            $0.right.equalToSuperview().inset(12.resize)
        }
        
        toolBarView.snp.makeConstraints {
            $0.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(44)
        }
        
        pkView.snp.makeConstraints { make in
            make.top.equalTo(roomNoticeView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(12)
        }
        guard let bubble = musicInfoBubbleView else {
            return
        }
        view.addSubview(bubble)
        bubble.snp.makeConstraints { make in
            make.top.equalTo(moreButton.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 150, height: 50))
        }
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(noti:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func bubbleViewAddGesture() {
        guard let bubble = musicInfoBubbleView else {
            return
        }
        bubble.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action:#selector(presentMusicController))
        bubble.addGestureRecognizer(tap)
    }
    
    @objc func presentMusicController() {
        //观众不展示音乐列表
        if (!self.voiceRoomInfo.isOwner) {return}
        RCMusicEngine.shareInstance().show(in: self, completion: nil)
    }
    
    @objc private func handleNotification(noti: Notification) {
        if isRoomClosed, let vc = UIApplication.shared.topmostController(), vc == self {
            navigator(.voiceRoomAlert(title: "当前直播已结束", actions: [.confirm("确定")], alertType: alertTypeVideoAlreadyClose, delegate: self))
        }
    }
    
    //MARK: - dynamic funcs
    ///设置模块，在viewDidLoad中调用
    dynamic func setupModules() {}
    ///消息回调，在engine模块中触发
    dynamic func handleReceivedMessage(_ message: RCMessage) {}
}

extension VoiceRoomViewController {
    private func setupVoiceRoom() {
        SVProgressHUD.show()
        var roomKVInfo: RCVoiceRoomInfo?
        if isCreate {
            let kvRoom = RCVoiceRoomInfo()
            kvRoom.roomName = voiceRoomInfo.roomName
            kvRoom.seatCount = 9
            roomKVInfo = kvRoom
        }
        moreButton.isEnabled = false
        SceneRoomManager.shared
            .voice_join(voiceRoomInfo.roomId, roomKVInfo: roomKVInfo) { [weak self] result in
                guard let self = self else { return }
                self.moreButton.isEnabled = true
                switch result {
                case .success:
                    SceneRoomManager.shared.currentRoom = self.voiceRoomInfo
                    SVProgressHUD.dismiss()
                    self.sendJoinRoomMessage()
                  
                case let .failure(error):
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                }
            }
        RCSensorAction.joinRoom(voiceRoomInfo, enableMic: false, enableCamera: false).trigger()
    }
    
    
    func autoEnterSeat() {
        if currentUserRole() == .creator {
            enterSeat(index: 0) {
                [weak self] in
                self?.getPKStatus()
            }
        } else {
            getPKStatus()
        }
    }
    
    func leaveRoom() {
        RCSceneMusic.clear()
        SceneRoomManager.shared
            .voice_leave { [weak self] result in
                SceneRoomManager.shared.currentRoom = nil
                self?.backTrigger()
                if let fm = self?.floatingManager {
                    fm.hide()
                }
                RCSceneMusic.clear()
                switch result {
                case .success:
                    print("leave room success")
                case let .failure(error):
                    print("leave room fail: \(error.localizedDescription)")
                }
            }
        RCSensorAction.quitRoom(voiceRoomInfo,
                                enableMic: enableMic,
                                enableCamera: false).trigger()
    }
    
    /// 关闭房间
    func closeRoom() {
        SVProgressHUD.show()
        RCSceneMusic.clear()
        voiceRoomService.closeRoom(roomId: voiceRoomInfo.roomId) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                switch result.map(RCSceneResponse.self) {
                case let .success(response):
                    if response.validate() {
                        SVProgressHUD.showSuccess(withStatus: "直播结束，房间已关闭")
                        self?.leaveRoom()
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "关闭房间失败")
                    }
                case .failure:
                    SVProgressHUD.showSuccess(withStatus: "关闭房间失败")
                }
            }
        }
        RCSensorAction.closeRoom(voiceRoomInfo,
                                 enableMic: enableMic,
                                 enableCamera: false).trigger()
    }
}

extension VoiceRoomViewController {
    func fetchManagers() {
        voiceRoomService.roomManagers(roomId: voiceRoomInfo.roomId) { [weak self] result in
            switch result.map(managersWrapper.self) {
            case let .success(wrapper):
                guard let self = self else { return }
                self.managers = wrapper.data ?? []
                if wrapper.code == 30001 {
                    self.currentRoomDidClosed()
                }
            case let.failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func currentRoomDidClosed() {
        view.subviews.forEach {
            if $0 == roomInfoView { return }
            $0.removeFromSuperview()
        }
        roomInfoView.updateRoom(info: voiceRoomInfo)
        
        let tipLabel = UILabel()
        tipLabel.text = "该房间直播已结束"
        tipLabel.textColor = .white
        tipLabel.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.618)
        }
        
        let tipButton = UIButton()
        tipButton.setTitle("返回房间列表", for: .normal)
        tipButton.setTitleColor(.white, for: .normal)
        tipButton.backgroundColor = .lightGray
        tipButton.layer.cornerRadius = 6
        tipButton.layer.masksToBounds = true
        tipButton.addTarget(self, action: #selector(backToRoomList), for: .touchUpInside)
        view.addSubview(tipButton)
        tipButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(1.1)
            make.width.equalTo(150)
            make.height.equalTo(50)
        }
    }
    
    @objc private func backToRoomList() {
        leaveRoom()
    }
    
    func currentUserRole() -> SceneRoomUserType {
        if Environment.currentUserId == voiceRoomInfo.userId {
            return .creator
        }
        if managers.contains(where: { Environment.currentUserId == $0.userId }) {
            return .manager
        }
        return .audience
    }
    
    var enableMic: Bool {
        let tmpSeat = seatList.first(where: { $0.seatUser?.userId == Environment.currentUserId })
        guard let seat = tmpSeat else { return false }
        if RCVoiceRoomEngine.sharedInstance().isDisableAudioRecording() {
            return false
        }
        return !seat.isMuted
    }
}

extension VoiceRoomViewController: RCIMReceiveMessageDelegate {
    func onRCIMCustomAlertSound(_ message: RCMessage!) -> Bool {
        return true
    }
}
