//
//  AppDelegate.swift
//  FaceLockProject
//
//  Created by 姚中天 on 2020/1/29.
//  Copyright © 2020 zh0ngtian. All rights reserved.
//

import Cocoa
import AVKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    var displaySleep = false
    var screenSaverDidStart = false
    var keyMouseMonitors = [Any?]()
    
    // MARK: - 请求权限
    // 请求辅助功能权限
    func askForAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        if !AXIsProcessTrustedWithOptions([key: true] as CFDictionary) {
            // Sometimes Prompt option above doesn't work.
            // Actually trying to send key may open that dialog.
            let src = CGEventSource(stateID: .hidSystemState)
            // "Fn" key down and up
            CGEvent(keyboardEventSource: src, virtualKey: 63, keyDown: true)?.post(tap: .cghidEventTap)
            CGEvent(keyboardEventSource: src, virtualKey: 63, keyDown: false)?.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - 状态处理
    // 解锁时
    @objc func onUnlock() {
        print("\(Date(timeIntervalSinceNow: 0)) -> onUnlock")
        
        if !self.keyMouseMonitors.isEmpty {
            let keyMouseMonitor = keyMouseMonitors[0]
            NSEvent.removeMonitor(keyMouseMonitor!)
            self.keyMouseMonitors.removeAll()
        }
        self.displaySleep = false
        self.screenSaverDidStart = false
    }
    
    // 显示器睡眠时
    @objc func onDisplaySleep() {
        print("\(Date(timeIntervalSinceNow: 0)) -> onDisplaySleep")
        
        if !self.keyMouseMonitors.isEmpty {
            let keyMouseMonitor = keyMouseMonitors[0]
            NSEvent.removeMonitor(keyMouseMonitor!)
            self.keyMouseMonitors.removeAll()
        }
        self.displaySleep = true
        self.screenSaverDidStart = false
    }
    
    // 显示器唤醒时
    @objc func onDisplayWake() {
        print("\(Date(timeIntervalSinceNow: 0)) -> onDisplayWake")
        self.tryUnlockScreen()
    }
    
    // 屏保开始时
    @objc func onScreensaverDidStart() {
        print("\(Date(timeIntervalSinceNow: 0)) -> onScreensaverDidStart")
        
        self.screenSaverDidStart = true
        let keyMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .mouseMoved]) { _ in
            self.tryUnlockScreen()
        }
        keyMouseMonitors.append(keyMouseMonitor)
    }
    
    // MARK: - 解锁屏幕
    // 判断当前是否锁屏
    func isScreenLocked() -> Bool {
        if let dict = CGSessionCopyCurrentDictionary() as? [String : Any] {
            if let locked = dict["CGSSessionScreenIsLocked"] as? Int {
                return locked == 1
            }
        }
        return false
    }
    
    // 尝试解锁屏幕
    func tryUnlockScreen() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else { return }
        guard self.isScreenLocked() else { return }
        // TODO: - 检查有无特征
        // TODO: - 检查有无密码
        
        let pc = PhotoCapturer()
        pc.startCapture()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
//            self.imageView2.image = self.capturedImage
            if (pc.flag == false) {
                pc.stopCapture()
                timer.invalidate()
            }
        })
        RunLoop.current.add(timer, forMode: .common)
        
        // debug
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            pc.flag = false
        }
    }

    // MARK: - 主函数
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // askForAccessibility()
        
        let nc = NSWorkspace.shared.notificationCenter
        let dnc = DistributedNotificationCenter.default()
        
        nc.addObserver(self, selector: #selector(onDisplaySleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(onDisplayWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        dnc.addObserver(self, selector: #selector(onUnlock), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)
        dnc.addObserver(self, selector: #selector(onScreensaverDidStart), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"), object: nil)
        
        let a = Bundle.main.path(forResource: "det1", ofType: "bin")
        let b = Bundle.main.path(forResource: "det2", ofType: "bin")
        print(b)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
