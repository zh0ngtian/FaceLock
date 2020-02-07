# FaceLock
FaceLock is a small menu bar application that can unlock your mac with your face.

## Requirements

macOS 10.14 (Mojave) or later

## Installation

Download zip file from [Releases](https://github.com/zh0ngtian/FaceLock/releases), unzip and copy to Applications folder. 

## Attention

FaceLock does not yet support face anti-spoofing, which means that your photos can be used to unlock your mac.

## Compile from source code

### Prepare dependence

* compile and install [NCNN](https://github.com/Tencent/ncnn)
* compile and install [opencv-3.4.9](https://github.com/opencv/opencv/archive/3.4.9.zip)
* `python2 your_project_path/opencv-3.4.9/platforms/osx/build_framework.py osx`

### Compile from source code

* git clone https://github.com/zh0ngtian/FaceLock.git`
* open `your_project_path/FaceLock/FaceLock.xcodeproj` with Xcode
* `FaceLock (top line of the left sidebar) -> TARGETS -> Build Phases -> Link Binary With Libraries`
    * add `Accelerate.framework`
    * add `OpenCL.framework`
    * add `your_project_path/opencv-3.4.9/platforms/osx/osx/opencv2.framework`
    * add `your_project_path/ncnn/build/install/lib/libncnn.a`
* `FaceLock (top line of the left sidebar) -> TARGETS -> Build Settings -> Search Paths`
    * Framework Search Paths:  `your_project_path/FaceLock`
    * Header search paths: `your_project_path/ncnn/build/install/include/ncnn`
    * Library Search Paths: `your_project_path/ncnn/build/install/lib`

## TODO

- [ ] Support more faces
- [ ] Use more powerful CNN model
- [ ] Support simple face anti-spoofing

## Reference

* [BLEUnlock](https://github.com/ts1/BLEUnlock)
* [ncnn-mtcnn-facenet](https://github.com/xuduo35/ncnn-mtcnn-facenet/tree/master/MacOS)

* Icon made by [smashicons](https://www.flaticon.com/authors/smashicons) from [www.flaticon.com](http://www.flaticon.com/)