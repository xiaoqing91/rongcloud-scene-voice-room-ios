//
//  HomeViewController.swift
//  RCSceneExample
//
//  Created by shaoshuai on 2022/5/26.
//

import RCSceneVoiceRoom

/// Connection
extension HomeViewController {
    func connection() {
        if RCIM.shared().getConnectionStatus() == .ConnectionStatus_Connected {
            return
        }
        guard let token = UserDefaults.standard.rongToken() else {
            return performSegue(withIdentifier: "Login", sender: nil)
        }
        RCIM.shared().initWithAppKey(Environment.rcKey)
        RCIM.shared().connect(withToken: token) { code in
            debugPrint("RCIM db open failed: \(code.rawValue)")
        } success: { userId in
            debugPrint("userId: \(userId ?? "")")
            self.refresh()
        } error: { errorCode in
            debugPrint("RCIM connect failed: \(errorCode.rawValue)")
        }
        RCIM.shared().addConnectionStatusDelegate(self)
    }
}

extension HomeViewController: RCIMConnectionStatusDelegate {
    func onRCIMConnectionStatusChanged(_ status: RCConnectionStatus) {
        switch status {
        case .ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT:
            logout()
        default: ()
        }
    }
    
    func logout() {
        UserDefaults.standard.clearLoginStatus()
        performSegue(withIdentifier: "Login", sender: nil)
    }
}
