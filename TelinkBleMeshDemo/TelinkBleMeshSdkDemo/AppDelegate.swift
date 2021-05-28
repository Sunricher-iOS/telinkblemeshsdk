//
//  AppDelegate.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/1/13.
//

import UIKit
import TelinkBleMesh

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        setUpWindow()
        
        return true
    }

}

extension AppDelegate {
    
    private func setUpWindow() {
        
        let nodes = NodesViewController(style: .grouped)
        let peripheralsController = UINavigationController(rootViewController: nodes)
        peripheralsController.tabBarItem.title = "nodes".localization
        
        let networks = NetworksViewController(style: .grouped)
        let networksController = UINavigationController(rootViewController: networks)
        networksController.tabBarItem.title = "networks".localization
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            networksController,
            peripheralsController,
        ]
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if #available(iOS 13.0, *) {
            window?.backgroundColor = .systemBackground
        } else {
            window?.backgroundColor = .white
        }
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }
    
}

