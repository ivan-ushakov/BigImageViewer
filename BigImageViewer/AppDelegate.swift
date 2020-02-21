//
//  AppDelegate.swift
//  BigImageViewer
//
//  Created by  Ivan Ushakov on 21.02.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.clear

        window?.rootViewController = UINavigationController(rootViewController: FilesViewController())
        window?.makeKeyAndVisible()

        return true
    }
}
