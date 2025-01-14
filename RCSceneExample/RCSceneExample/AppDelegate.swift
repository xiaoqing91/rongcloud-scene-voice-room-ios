//
//  AppDelegate.swift
//  RCSceneExample
//
//  Created by shaoshuai on 2022/3/19.
//

import UIKit
import SVProgressHUD

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        SVProgressHUD.setMaximumDismissTimeInterval(1.2)
        AppConfigs.config()
        
        return true
    }

}
