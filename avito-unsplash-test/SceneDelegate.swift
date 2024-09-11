//
//  SceneDelegate.swift
//  avito-unsplash-test
//
//  Created by Марк Кулик on 07.09.2024.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

       func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
           // Ensure the scene is a UIWindowScene
           guard let windowScene = (scene as? UIWindowScene) else { return }
           
           // Create the window and set its frame to the size of the window scene
           window = UIWindow(windowScene: windowScene)
           
           // Create an instance of the root view controller
           let searchViewController = SearchViewController()
           
           // Embed the searchViewController in a UINavigationController
           let navigationController = UINavigationController(rootViewController: searchViewController)
           
           // Set the root view controller of the window
           window?.rootViewController = navigationController
           
           // Make the window key and visible
           window?.makeKeyAndVisible()
       }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

