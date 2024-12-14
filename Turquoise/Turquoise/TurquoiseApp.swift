//
//  TurquoiseApp.swift
//  Turquoise
//
//  Created by 罗板栗 on 2024/12/12.
//

import SwiftUI
import UserNotifications
import UIKit
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        checkNotificationAuthorization()
        return true
    }
    
    func checkNotificationAuthorization() {
        print("🔔 Checking notification authorization...")
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Authorization status: \(settings.authorizationStatus.rawValue)")
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.requestNotificationPermission()
                case .denied:
                    // Show alert to guide user to settings
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let viewController = windowScene.windows.first?.rootViewController {
                        let alert = UIAlertController(
                            title: "通知权限未开启",
                            message: "请在设置中开启通知权限以接收重要消息",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        })
                        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                        viewController.present(alert, animated: true)
                    }
                case .authorized, .provisional, .ephemeral:
                    print("✅ Notification authorized, registering for remote notifications...")
                    UIApplication.shared.registerForRemoteNotifications()
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        print("🔔 Requesting notification permission...")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Permission granted, registering for remote notifications...")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("❌ Permission denied")
                }
                if let error = error {
                    print("❌ Error requesting notification permission: \(error)")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 Received device token: \(token)")
        UserDefaults.standard.set(token, forKey: "APNSDeviceToken")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("🔗 Received universal link activity")
        
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            print("❌ Not a web browsing activity")
            return false
        }
        
        guard let url = userActivity.webpageURL else {
            print("❌ No webpage URL found")
            return false
        }
        print("📍 URL: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("❌ Could not parse URL components")
            return false
        }
        print("🛣️ Path: \(components.path)")
        print("❓ Query items: \(String(describing: components.queryItems))")
        
        if components.path.hasPrefix("/endpoint/"),
           let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value,
           let nameParam = components.queryItems?.first(where: { $0.name == "name" })?.value {
            print("✅ Found valid endpoint parameters")
            print("📝 Name: \(nameParam)")
            print("🔗 URL: \(urlParam)")
            
            EndpointManager.shared.addEndpoint(name: nameParam, url: urlParam)
            return true
        }
        
        print("❌ Could not find required parameters")
        return false
    }
}

@main
struct TurquoiseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Endpoint.self, RuleSet.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .onAppear {
                    appDelegate.checkNotificationAuthorization()
                }
        }
    }
}
