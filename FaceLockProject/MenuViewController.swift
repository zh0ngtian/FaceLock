//
//  MenuViewController.swift
//  iFaceProject
//
//  Created by 姚中天 on 2020/1/29.
//  Copyright © 2020 zh0ngtian. All rights reserved.
//

import Cocoa
import Quartz
import AVKit

class MenuViewController: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    var displaySleep = false
    var screenSaverDidStart = false
    var keyMouseMonitors = [Any?]()
    var recognizer: CV
    
    // MARK: - 工具函数
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
    
    // 完成拍照或者照片选择后的回调
    @objc func pictureTakerValidated(pictureTaker: IKPictureTaker, returnCode: NSInteger, contextInfo: UnsafeRawPointer) {
        if (returnCode == NSApplication.ModalResponse.OK.rawValue) {
            let outputImage: NSImage = pictureTaker.outputImage()
            let fea: NSMutableArray = self.recognizer.getFea(outputImage)
            print(fea)
            // TODO: 存储特征
        }
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
        // TODO: 检查有无特征
        // TODO: 检查有无密码
        
        let pc = PhotoCapturer()
        pc.startCapture()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            // TODO: 验证图片 self.capturedImage
            if (pc.flag == false) {
                pc.stopCapture()
                timer.invalidate()
            }
        })
        RunLoop.current.add(timer, forMode: .common)
        
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
//            pc.flag = false
//        }
    }
    
    // 输入密码
    func typePassword() {
        // TODO
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
    
    // MARK: - 初始化
    // 类初始化
    override init() {
        let fullPath = String(Bundle.main.path(forResource: "det1", ofType: "bin")!)
        let deRange = fullPath.range(of: "/det1.bin")
        let modelPath = String(fullPath.prefix(upTo: deRange!.lowerBound))
        self.recognizer = CV(modelPath: modelPath, minFace: 40)
        
        super.init()
        
        // TODO: 类初始化时加载特征
    }
    
    // 菜单初始化
    @IBOutlet weak var faceMenu: NSMenu!
    let faceStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override func awakeFromNib() {
        faceStatusItem.title = "FaceLock"
        faceStatusItem.menu = faceMenu
        
        // askForAccessibility()
        let nc = NSWorkspace.shared.notificationCenter
        let dnc = DistributedNotificationCenter.default()
        
        nc.addObserver(self, selector: #selector(onDisplaySleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(onDisplayWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        dnc.addObserver(self, selector: #selector(onUnlock), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)
        dnc.addObserver(self, selector: #selector(onScreensaverDidStart), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"), object: nil)
    }
    
    // MARK: - 按钮操作
    // Add Face
    @IBAction func addFaceAction(_ sender: NSMenuItem) {
        let pictureTaker = IKPictureTaker()
        let picUrl: URL
        let bundle = Bundle()
        if (bundle.isLoaded) {
            let picPath = bundle.path(forResource: "picture", ofType: "jpg")
            if ((picPath) != nil) {
                picUrl = URL.init(fileURLWithPath: picPath!)
                pictureTaker.setInputImage(NSImage.init(byReferencing: picUrl))
            }
        }
        pictureTaker.begin(withDelegate: self, didEnd: #selector(pictureTakerValidated(pictureTaker:returnCode:contextInfo:)), contextInfo: nil)
    }
    
    // Add Password
    @IBAction func addPasswordAction(_ sender: NSMenuItem) {
        // TODO
        print("Add Password")
    }
    
    // Setting
    @IBAction func settingAction(_ sender: NSMenuItem) {
        print("Setting")
    }
    
    // Quit
    @IBAction func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
}
