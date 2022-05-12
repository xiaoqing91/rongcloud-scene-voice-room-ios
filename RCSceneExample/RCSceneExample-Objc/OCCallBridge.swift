//
//  VoiceRoom.swift
//  RCSceneExample-Objc
//
//  Created by hanxiaoqing on 2022/4/26.
//

import Foundation
import RCSceneRoom
import RCSceneVoiceRoom

@objc public protocol LoginBridgeDelegate {
    @objc func loginCompletion(result: String?, error: NSError?);
}

@objc public class LoginBridge: NSObject {
    @objc weak var delegate: LoginBridgeDelegate?
    
    @objc public func login(mobile: String) {
        let deviceId = UIDevice.current.identifierForVendor!.uuidString
        let api = RCLoginService.login(mobile: mobile,
                                       code: "123456",
                                       userName: nil,
                                       portrait: nil,
                                       deviceId: deviceId,
                                       region: "+86",
                                       platform: "mobile")
        
        loginProvider.request(api) { result in
            switch result.map(RCSceneWrapper<User>.self) {
            case let .success(wrapper):
                let user = wrapper.data!
                UserDefaults.standard.set(user: user)
                UserDefaults.standard.set(authorization: user.authorization)
                UserDefaults.standard.set(rongCloudToken: user.imToken)
                self.delegate?.loginCompletion(result: "success", error: nil)
            case let .failure(error):
                let ocErr = NSError(domain: "login", code: -1, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                self.delegate?.loginCompletion(result: nil, error: ocErr)
            }
        }
    }
}


@objc public protocol VoiceRoomBridgeDelegate {
    @objc func getRoomListCompletion(result: [RCSceneRoomInfo]?, error: NSError?);
}

@objc public class VoiceRoomBridge: NSObject {
    @objc weak var delegate: VoiceRoomBridgeDelegate?
    
    var rooms: [RCSceneRoom]?
    
    @objc public func userDefaultsSavedToken() -> String {
        UserDefaults.standard.rongToken()  ?? ""
    }

    struct VoiceRoomList: Codable {
        let totalCount: Int
        let rooms: [RCSceneRoom]
        let images: [String]
    }

    @objc public func getRoomList() {
        roomProvider.request(.roomList(type: 1, page: 1, size: 20)) { result in
            switch result {
            case let .success(dataResponse):
                let wrapper = try! JSONDecoder().decode(RCSceneWrapper<VoiceRoomList>.self, from: dataResponse.data)
                SceneRoomManager.shared.backgrounds = wrapper.data?.images ?? [""]
                self.rooms = wrapper.data?.rooms
                
                let ocRoomlist = RCNetResponseWrapper.yy_model(withJSON: dataResponse.data)
                self.delegate?.getRoomListCompletion(result: ocRoomlist?.data.rooms, error: nil)
            case let .failure(error):
                let ocErr = NSError(domain: "getRoomList", code: -2, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                self.delegate?.getRoomListCompletion(result: nil, error: ocErr)
            }
        }
    }
    
    @objc public func createRoom(fromVc: UIViewController, name: String) {
        let imageUrl = "https://img2.baidu.com/it/u=2842763149,821152972&fm=26&fmt=auto"
        roomProvider.request(.createRoom(name: name, themePictureUrl: imageUrl, backgroundUrl: imageUrl, kv: [], isPrivate: 0, password: "1234", roomType: 1)) { result in
            switch result {
            case let .success(dataResponse):
                let wrapper = try! JSONDecoder().decode(RCSceneWrapper<RCSceneRoom>.self, from: dataResponse.data)
                ;
                guard let roomInfo = wrapper.data else { return  }
                let controller = RCVoiceRoomController(room: roomInfo, creation: true)
                controller.view.backgroundColor = .black
                fromVc.navigationController?.navigationBar.isHidden = true
                fromVc.navigationController?.pushViewController(controller, animated: true)
               
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    
    
    @objc public func enterVoiceRoom(fromVc: UIViewController, roomId: String) {
        guard let roomInfo = self.rooms?.filter({ $0.roomId == roomId }).first else {
            return
        }
        let controller = RCVoiceRoomController(room: roomInfo)
        controller.view.backgroundColor = .black
        fromVc.navigationController?.navigationBar.isHidden = true
        fromVc.navigationController?.pushViewController(controller, animated: true)
    }
}


