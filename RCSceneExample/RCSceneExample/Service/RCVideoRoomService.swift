//
//  RCVideoRoomService.swift
//  RCSceneExample
//
//  Created by shaoshuai on 2022/3/29.
//

import Foundation
import RCSceneRoom

let service = RCVideoRoomService()

struct VoiceRoomList: Codable {
    let totalCount: Int
    let rooms: [RCSceneRoom]
    let images: [String]
}

class RCVideoRoomService {
    func login(phone: String, completion: @escaping (Result<Void, NetError>) -> Void) {
        let deviceId = UIDevice.current.identifierForVendor!.uuidString
        let api = RCLoginService.login(mobile: phone,
                                       code: "123456",
                                       userName: nil,
                                       portrait: nil,
                                       deviceId: deviceId,
                                       region: "+86",
                                       platform: "mobile")
        
        loginProvider.request(api) { result in
            switch result.map(RCNetworkWrapper<User>.self) {
            case let .success(wrapper):
                let user = wrapper.data!
                UserDefaults.standard.set(user: user)
                UserDefaults.standard.set(authorization: user.authorization)
                UserDefaults.standard.set(rongCloudToken: user.imToken)
                completion(.success(()))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func roomList(type: Int = 1,
                  page: Int = 1,
                  size: Int = 20,
                  completion: @escaping (Result<[RCSceneRoom], NetError>) -> Void)
    {
        roomProvider.request(.roomList(type: type, page: page, size: size)) { result in
            switch result.map(RCNetworkWrapper<VoiceRoomList>.self) {
            case let .success(wrapper):
                if let list = wrapper.data {
                    SceneRoomManager.shared.backgrounds = list.images
                    completion(.success(list.rooms))
                } else {
                    completion(.failure(NetError("加载失败")))
                }
            case let .failure(error):
                completion(.failure(NetError(error.localizedDescription)))
            }
        }
    }
    
    func createRoom(name: String,
                    completion: @escaping (Result<RCSceneRoom, NetError>) -> Void) {
        let imageUrl = "https://img2.baidu.com/it/u=2842763149,821152972&fm=26&fmt=auto"
        roomProvider.request(.createRoom(name: name, themePictureUrl: imageUrl, backgroundUrl: imageUrl, kv: [], isPrivate: 0, password: "1234", roomType: 1)) { result in
            switch result.map(RCNetworkWrapper<RCSceneRoom>.self) {
            case let .success(wrapper):
                if let roomInfo = wrapper.data {
                    completion(.success(roomInfo))
                } else {
                    completion(.failure(NetError("加载失败")))
                }
            case let .failure(error):
                completion(.failure(NetError(error.localizedDescription)))
            }
        }
    }
    
    
}
