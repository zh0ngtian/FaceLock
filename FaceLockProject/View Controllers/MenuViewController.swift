//
//  MenuViewController.swift
//  iFaceProject
//
//  Created by 姚中天 on 2020/1/29.
//  Copyright © 2020 zh0ngtian. All rights reserved.
//

import Cocoa
import Quartz

class MenuViewController: NSObject, NSUserNotificationCenterDelegate {
    
    func setImageInputForPictureTaker(pictureTaker: IKPictureTaker) {
        let picUrl: URL
        let bundle = Bundle()
        if (bundle.isLoaded) {
            let picPath = bundle.path(forResource: "picture", ofType: "jpg")
            if ((picPath) != nil) {
                picUrl = URL.init(fileURLWithPath: picPath!)
                pictureTaker.setInputImage(NSImage.init(byReferencing: picUrl))
            }
        }
    }
    
    @objc func pictureTakerValidated(pictureTaker: IKPictureTaker, returnCode: NSInteger, contextInfo: UnsafeRawPointer) {
        if (returnCode == NSApplication.ModalResponse.OK.rawValue) {
            let outputImage: NSImage = pictureTaker.outputImage()
            let fea: NSMutableArray = CV.getFea(outputImage, withMinFace: 40)
            print(fea)
        }
    }
    
    // menuApp 的菜单栏
    @IBOutlet weak var faceMenu: NSMenu!
    let faceStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override func awakeFromNib() {
        faceStatusItem.title = "FaceLock"
        faceStatusItem.menu = faceMenu
    }
    
    @_silgen_name("mySwiftFunction")  // vital for the function being visible from C
    func mySwiftFunction(a: Int, b: Int) -> Int {
        return a + b
    }
    
    // Add Face 按钮操作
    @IBAction func addFaceAction(_ sender: NSMenuItem) {
        let pictureTaker = IKPictureTaker()
        self.setImageInputForPictureTaker(pictureTaker: pictureTaker)
        pictureTaker.begin(withDelegate: self, didEnd: #selector(pictureTakerValidated(pictureTaker:returnCode:contextInfo:)), contextInfo: nil)
//        let fea: NSMutableArray = CV.getFea(40)
//        print(fea)
    }
    
    // Add Password 按钮操作
    @IBAction func addPasswordAction(_ sender: NSMenuItem) {
        print("Add Password")
    }
    
    // Setting 按钮操作
    @IBAction func settingAction(_ sender: NSMenuItem) {
        print("Setting")
    }
    
    // Quit 按钮操作
    @IBAction func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
}
