//
//  MenuViewController.swift
//  FaceLock
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

    var KEY_FOR_FEA = "user_face_feature"
    var KEY_FOR_PASSWD = "user_password"
    
    // MARK: - 工具函数
    // 请求辅助功能权限
    func askForAccessibility() {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let accessEnabled = AXIsProcessTrustedWithOptions([checkOptPrompt: true] as CFDictionary)
        if !accessEnabled {
            // Sometimes Prompt option above doesn't work, actually trying to send key may open that dialog.
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
            let feaMutatle: NSMutableArray = self.recognizer.getFea(outputImage)
            let feaArray: Array = feaMutatle as Array
            UserDefaults.standard.set(feaArray, forKey: KEY_FOR_FEA)
        }
    }
    
    // 模拟键盘输入
    func fakeKeyStrokes(str: String) {
        let src = CGEventSource(stateID: .hidSystemState)
        let pressEvent = CGEvent(keyboardEventSource: src, virtualKey: 49, keyDown: true)
        let len = str.count
        let buffer = UnsafeMutablePointer<UniChar>.allocate(capacity: len)
        NSString(string:str).getCharacters(buffer)
        pressEvent?.keyboardSetUnicodeString(stringLength: len, unicodeString: buffer)
        pressEvent?.post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: src, virtualKey: 49, keyDown: false)?.post(tap: .cghidEventTap)
        
        // Return key
        CGEvent(keyboardEventSource: src, virtualKey: 52, keyDown: true)?.post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: src, virtualKey: 52, keyDown: false)?.post(tap: .cghidEventTap)
    }
    
    // 请求用户密码
    func askForPassword() -> String {
        func t(_ key: String) -> String {
            return NSLocalizedString(key, comment: "")
        }
        
        let msg = NSAlert()
        msg.addButton(withTitle: t("OK"))
        msg.addButton(withTitle: t("Cancel"))
        msg.messageText = t("Enter Password")
        msg.informativeText = t("Password will be used to unlock screen.")
        msg.window.title = "FaceLock"

        let txt = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 20))
        msg.accessoryView = txt
        txt.becomeFirstResponder()
        NSApp.activate(ignoringOtherApps: true)
        let response = msg.runModal()
        
        if (response == .alertFirstButtonReturn) {
            return txt.stringValue
        }
        return ""
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
        guard self.isScreenLocked() else { return }
        
        // 检查相机权限
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else { return }
        
        // 检查辅助功能权限
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let accessEnabled = AXIsProcessTrustedWithOptions([checkOptPrompt: true] as CFDictionary)
        guard accessEnabled else { return }
        
        // 检查是否设置人脸
        let feaArray = UserDefaults.standard.array(forKey: KEY_FOR_FEA)
        guard feaArray != nil else { return }
        
        // 检查是否设置密码
        let passwd = UserDefaults.standard.string(forKey: KEY_FOR_PASSWD)
        guard passwd != nil else { return }
        
        let pc = PhotoCapturer()
        pc.startCapture()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            let feaMutatle = NSMutableArray()
            feaMutatle.addObjects(from: feaArray!)
                        
            let similarity = self.recognizer.verify(pc.capturedImage, withTargetFea: feaMutatle)
            if similarity > 0.65 {
                self.fakeKeyStrokes(str: passwd!)
                pc.stopCapture()
                timer.invalidate()
            } else {
                print("Wrong face.")
            }
            
            if self.displaySleep {
                timer.invalidate()
                pc.stopCapture()
            }
        })
        RunLoop.current.add(timer, forMode: .common)
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
        self.displaySleep = false
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
    }
    
    // 菜单初始化
    override func awakeFromNib() {
        if let button = faceStatusItem.button {
            button.image = NSImage(named: "StatusIcon")
        }
        faceStatusItem.menu = faceMenu
        
        self.askForAccessibility()
        let nc = NSWorkspace.shared.notificationCenter
        let dnc = DistributedNotificationCenter.default()
        
        nc.addObserver(self, selector: #selector(onDisplaySleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(onDisplayWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        dnc.addObserver(self, selector: #selector(onUnlock), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)
        dnc.addObserver(self, selector: #selector(onScreensaverDidStart), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"), object: nil)
    }
    
    // MARK: - 按钮操作
     @IBOutlet weak var faceMenu: NSMenu!
     let faceStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
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
        // TODO: 添加大图标和小图标
        let passwd = self.askForPassword()
        if passwd != "" {
            UserDefaults.standard.set(passwd, forKey: KEY_FOR_PASSWD)
        }
    }
    
    // Quit
    @IBAction func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
}
