//
//  RCRouter.swift
//  RCE
//
//  Created by 叶孤城 on 2021/4/20.
//

import UIKit
import RCSceneRoom

enum RCNavigation: Navigation {
    case voiceRoom(roomInfo: RCSceneRoom, needCreate: Bool)
    case requestOrInvite(roomId: String, delegate: HandleRequestSeatProtocol, showPage: Int, onSeatUserIds:[String]?, requesterIds:[String])
    case masterSeatOperation(String, Bool, VoiceRoomMasterSeatOperationProtocol)
    case userSeatPop(seatIndex: UInt, isUserMute: Bool, isSeatMute: Bool, delegate: VoiceRoomSeatedOperationProtocol)
    case manageUser(dependency: RCSceneRoomUserOperationDependency, delegate: RCSceneRoomUserOperationProtocol?)
    case ownerClickEmptySeat(RCVoiceSeatInfo, UInt, VoiceRoomEmptySeatOperationProtocol)
    case inputText(name: String, delegate: VoiceRoomInputTextProtocol)
    case inputPassword(completion: RCSRPasswordCompletion)
    case requestSeatPop(delegate: RequestSeatPopProtocol)
    case changeBackground(imageList: [String], delegate: ChangeBackgroundImageProtocol)
    case userList(room: RCSceneRoom, delegate: RCSceneRoomUserOperationProtocol)
    case gift(dependency: RCSceneGiftDependency, delegate: RCSceneGiftViewControllerDelegate)
    case voiceRoomAlert(title: String, actions: [VoiceRoomAlertAction], alertType: String, delegate: VoiceRoomAlertProtocol?)
    case leaveAlert(isOwner: Bool, delegate: RCSceneLeaveViewProtocol)
    case notice(modify: Bool = false, notice: String, delegate: VoiceRoomNoticeDelegate)
    case forbiddenList(roomId: String)
    case onlineRooms(selectingUserId: String?, delegate: OnlineRoomCreatorDelegate)
}

struct RCAppNavigation: AppNavigation {
    func navigate(_ navigation: Navigation, from: UIViewController, to: UIViewController) {
        if let router = navigation as? RCNavigation {
            switch router {
            case
                    .requestOrInvite,
                    .masterSeatOperation,
                    .userSeatPop,
                    .manageUser,
                    .ownerClickEmptySeat,
                    .inputText,
                    .inputPassword,
                    .requestSeatPop,
                    .changeBackground,
                    .userList,
                    .gift,
                    .voiceRoomAlert,
                    .leaveAlert,
                    .notice,
                    .forbiddenList,
                    .onlineRooms:
                from.present(to, animated: true, completion: nil)
            default:
                from.navigationController?.pushViewController(to, animated: true)
            }
        }
    }
    
    func viewControllerForNavigation(navigation: Navigation) -> UIViewController {
        guard let router = navigation as? RCNavigation else {
            return UIViewController()
        }
        switch router {
        case let .voiceRoom(roomInfo, needCreate):
            return VoiceRoomViewController(roomInfo: roomInfo, isCreate: needCreate)
        case let .requestOrInvite(roomId, delegate, page, list, requesterIds):
            return RequestOrInviteViewController(roomId: roomId, delegate: delegate, showPage: page, onSeatUserIds: list, requesterIds: requesterIds)
        case let .masterSeatOperation(userId, isMute, object):
            let vc = VoiceRoomMasterSeatOperationViewController(userId: userId, isMute: isMute, delegate: object)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .userSeatPop(seatIndex, isUserMute, isSeatMute, delegate):
            let vc = VoiceRoomSeatedOperationViewController(seatIndex: seatIndex, isMute: isUserMute,delegate: delegate, isSeatMute: isSeatMute)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .manageUser(dependency, delegate):
            let vc = RCSceneRoomUserOperationViewController(dependency: dependency, delegate: delegate)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .ownerClickEmptySeat(info, index, delegate):
            let vc = VoiceRoomEmptySeatOperationViewController(seatInfo: info, seatIndex: index, delegate: delegate)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .inputText(name, delegate):
            let vc = VoiceRoomTextInputViewController(name: name, delegate: delegate)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .inputPassword(completion):
            let vc = RCSRPasswordViewController()
            vc.completion = completion
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .requestSeatPop(delegate):
            let vc = ManageRequestSeatViewController(delegate: delegate)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .changeBackground(imageList, delegate):
            let vc = ChangeBackgroundViewController(imageList: imageList, delegate: delegate)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .userList(room, delegate):
            let vc = RCSceneRoomUsersViewController(room: room, delegate: delegate)
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
            nav.modalTransitionStyle = .coverVertical
            nav.modalPresentationStyle = .overFullScreen
            return nav
        case let .gift(dependency, delegate):
            let vc = RCSceneGiftViewController(dependency: dependency, delegate: delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .voiceRoomAlert(title, actions, alertType, delegate):
            let vc = VoiceRoomAlertViewController(title: title, actions: actions, alertType: alertType, delegate: delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .leaveAlert(isOwner, delegate):
            let vc = VoiceRoomLeaveAlertViewController(isOwner: isOwner, delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .notice(modify, notice ,delegate):
            let vc = VoiceRoomNoticeViewController(modify: modify, notice: notice, delegate: delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .forbiddenList(roomId):
            let vc = VoiceRoomForbiddenViewController(roomId: roomId)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .onlineRooms(userId, delegate):
            let vc = OnlineRoomCreatorViewController(selectingUserId: userId, delegate: delegate)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
            
        }
    }
}

extension UIViewController {
    @discardableResult
    func navigator(_ navigation: RCNavigation) -> UIViewController {
        return navigate(navigation as Navigation)
    }
}
