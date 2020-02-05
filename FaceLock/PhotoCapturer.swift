//
//  PhotoCapturer.swift
//  FaceLock
//
//  Created by 姚中天 on 2020/2/3.
//  Copyright © 2020 zh0ngtian. All rights reserved.
//

import Foundation
import AVKit

class PhotoCapturer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var session: AVCaptureSession!
    var device: AVCaptureDevice!
    var output: AVCaptureVideoDataOutput!
    var capturedImage: NSImage!
//    var flag = false
    
    func startCapture() {
//        self.flag = true
        
        // Prepare a video capturing session.
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSession.Preset.vga640x480
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("no device")
            return
        }
        self.device = device
        do {
            let input = try AVCaptureDeviceInput(device: self.device)
            self.session.addInput(input)
        } catch {
            print("no device input")
            return
        }
        self.output = AVCaptureVideoDataOutput()
        self.output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        let queue: DispatchQueue = DispatchQueue(label: "videocapturequeue", attributes: [])
        self.output.setSampleBufferDelegate(self, queue: queue)
        self.output.alwaysDiscardsLateVideoFrames = true
        if self.session.canAddOutput(self.output) {
            self.session.addOutput(self.output)
        } else {
            print("could not add a session output")
            return
        }

        self.session.startRunning()
    }
    
    func stopCapture() {
        self.session.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Convert a captured image buffer to NSImage.
        guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("could not get a pixel buffer")
            return
        }
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        let imageRep = NSCIImageRep(ciImage: CIImage(cvImageBuffer: buffer))
        let capturedImage = NSImage(size: imageRep.size)
        capturedImage.addRepresentation(imageRep)
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        self.capturedImage = capturedImage
    }
}
