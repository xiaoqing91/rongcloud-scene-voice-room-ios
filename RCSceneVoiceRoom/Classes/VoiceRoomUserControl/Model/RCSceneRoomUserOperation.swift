
import Foundation

struct RCSRUserOperationDependency {
    let room: RCSceneRoom
    
    let userId: String
    let userRole: SceneRoomUserType
    
    let userSeatIndex: Int?
    let userSeatMute: Bool?
    let userSeatLock: Bool?
    
    var isSeating: Bool {
        return userSeatIndex != nil
    }
    
    var currentUserId: String {
        Environment.currentUserId
    }
    
    var currentUserRole: SceneRoomUserType {
        if Environment.currentUserId == room.userId {
            return .creator
        }
        if SceneRoomManager.shared.managers.contains(currentUserId) {
            return .manager
        }
        return .audience
    }
    
    init(room: RCSceneRoom,
                userId: String,
                userRole: SceneRoomUserType = .audience,
                userSeatIndex: Int? = nil,
                userSeatMute: Bool? = false,
                userSeatLock: Bool? = false) {
        self.room = room
        self.userId = userId
        self.userRole = userRole
        self.userSeatIndex = userSeatIndex
        self.userSeatMute = userSeatMute
        self.userSeatLock = userSeatLock
    }
}
