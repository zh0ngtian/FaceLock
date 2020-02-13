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
    var first = false
    var displaySleep = false
    var screensaverDidStart = false
    
    var keyMouseMonitors = [Any?]()
    var capturer: PhotoCapturer
    var recognizer: CV

    var KEY_FOR_FEA = "user_face_feature"
    var KEY_FOR_PASSWD = "user_password"
    
    // MARK: - Utils
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
    
    @objc func pictureTakerValidated(pictureTaker: IKPictureTaker, returnCode: NSInteger, contextInfo: UnsafeRawPointer) {
        if (returnCode == NSApplication.ModalResponse.OK.rawValue) {
            let outputImage: NSImage = pictureTaker.outputImage()
            let feaMutatle: NSMutableArray = self.recognizer.getFea(outputImage)
            let feaArray: Array = feaMutatle as Array
            UserDefaults.standard.set(feaArray, forKey: KEY_FOR_FEA)
        }
    }
    
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
    
    // MARK: - Unlock
    func isScreenLocked() -> Bool {
        if let dict = CGSessionCopyCurrentDictionary() as? [String : Any] {
            if let locked = dict["CGSSessionScreenIsLocked"] as? Int {
                return locked == 1
            }
        }
        return false
    }
    
    func tryUnlockScreen() {
        print("\(Date(timeIntervalSinceNow: 0)) -> Try to unlock screen.")
        guard !self.displaySleep && self.isScreenLocked() else { return }
        
        // check cemera
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            print("\(Date(timeIntervalSinceNow: 0)) -> No cemera authority.")
            return
        }
        
        // check accessibility
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let accessEnabled = AXIsProcessTrustedWithOptions([checkOptPrompt: true] as CFDictionary)
        guard accessEnabled else {
            print("\(Date(timeIntervalSinceNow: 0)) -> No accessibility authority.")
            return
        }
        
        // check face
        let feaArray = UserDefaults.standard.array(forKey: KEY_FOR_FEA)
        guard feaArray != nil else {
            print("\(Date(timeIntervalSinceNow: 0)) -> No face saved.")
            return
        }
        let feaMutatle = NSMutableArray()
        feaMutatle.addObjects(from: feaArray!)
        
        // check password
        let passwd = UserDefaults.standard.string(forKey: KEY_FOR_PASSWD)
        guard passwd != nil else {
            print("\(Date(timeIntervalSinceNow: 0)) -> No password saved.")
            return
        }
        
        self.capturer.startCapture()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { timer in
            let ci = self.capturer.capturedImage
            if ci != nil {
                let similarity = self.recognizer.verify(ci, withTargetFea: feaMutatle)
                print("similarity: ", similarity)
                print()
                
                if similarity > 0.78 {
                    if !self.displaySleep && self.isScreenLocked() {
                        self.fakeKeyStrokes(str: passwd!)
                    }
                    self.capturer.stopCapture()
                    timer.invalidate()
                }
                
                if self.displaySleep || !self.isScreenLocked() {
                    self.capturer.stopCapture()
                    timer.invalidate()
                }
            }
        })
        RunLoop.current.add(timer, forMode: .common)
    }
    
    // MARK: - Observation
    @objc func onUnlock() {
        print("\(Date(timeIntervalSinceNow: 0)) -> on unlock")
        
        if !self.keyMouseMonitors.isEmpty {
            let keyMouseMonitor = keyMouseMonitors[0]
            NSEvent.removeMonitor(keyMouseMonitor!)
            self.keyMouseMonitors.removeAll()
        }
        self.displaySleep = false
        self.screensaverDidStart = false
         self.first = false
    }
    
    @objc func onLock() {
        print("\(Date(timeIntervalSinceNow: 0)) -> on lock")
    }
    
    @objc func onDisplaySleep() {
        print("\(Date(timeIntervalSinceNow: 0)) -> on display sleep")
        
        if !self.keyMouseMonitors.isEmpty {
            let keyMouseMonitor = keyMouseMonitors[0]
            NSEvent.removeMonitor(keyMouseMonitor!)
            self.keyMouseMonitors.removeAll()
        }
        self.displaySleep = true
        self.screensaverDidStart = false
        self.first = false
    }
    
    @objc func onDisplayWake() {
        print("\(Date(timeIntervalSinceNow: 0)) -> on display wake")
        self.displaySleep = false
        self.tryUnlockScreen()
    }
    
    @objc func onScreensaverDidStart() {
        print("\(Date(timeIntervalSinceNow: 0)) -> on screensaver didStart")
        
        let lock = NSLock()
        
        self.screensaverDidStart = true
        self.first = false
        let keyMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .mouseMoved]) { _ in
            lock.lock()
            if self.first == false {
                self.first = true
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    self.first = false
                }
                self.tryUnlockScreen()
            }
            lock.unlock()
        }
        keyMouseMonitors.append(keyMouseMonitor)
    }
    
    // MARK: - Initialization
    override init() {
        let fullPath = String(Bundle.main.path(forResource: "det1", ofType: "bin")!)
        let deRange = fullPath.range(of: "/det1.bin")
        let modelPath = String(fullPath.prefix(upTo: deRange!.lowerBound))
        
        self.recognizer = CV(modelPath: modelPath, minFace: 40)
        self.capturer = PhotoCapturer()
        
        super.init()
    }
    
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
        dnc.addObserver(self, selector: #selector(onLock), name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"), object: nil)
        dnc.addObserver(self, selector: #selector(onUnlock), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)
        dnc.addObserver(self, selector: #selector(onScreensaverDidStart), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"), object: nil)
    }
    
    // MARK: - Buttons
    @IBOutlet weak var faceMenu: NSMenu!
    let faceStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBAction func addFaceAction(_ sender: NSMenuItem) {
        let pictureTaker = IKPictureTaker()
        pictureTaker.setValue(false, forKey: IKPictureTakerAllowsEditingKey)
        if (Bundle().isLoaded) {
            let picPath = Bundle().path(forResource: "picture", ofType: "jpg")
            if ((picPath) != nil) {
                let picUrl = URL.init(fileURLWithPath: picPath!)
                pictureTaker.setInputImage(NSImage.init(byReferencing: picUrl))
            }
        }
        pictureTaker.begin(withDelegate: self, didEnd: #selector(pictureTakerValidated(pictureTaker:returnCode:contextInfo:)), contextInfo: nil)
    }
    
    @IBAction func addPasswordAction(_ sender: NSMenuItem) {
        let passwd = self.askForPassword()
        if passwd != "" {
            UserDefaults.standard.set(passwd, forKey: KEY_FOR_PASSWD)
        }
    }
    
    @IBAction func debugAction(_ sender: NSMenuItem) {
        let feaArray = UserDefaults.standard.array(forKey: KEY_FOR_FEA)
        guard feaArray != nil else { return }
        let feaMutatle = NSMutableArray()
        feaMutatle.addObjects(from: feaArray!)
        
        let pc = PhotoCapturer()
        pc.startCapture()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            let ci = pc.capturedImage
            if ci != nil {
                let similarity = self.recognizer.verify(ci, withTargetFea: feaMutatle)
                print("similarity: ", similarity)
            }
        })
        RunLoop.current.add(timer, forMode: .common)
    }
    
    @IBAction func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
}
