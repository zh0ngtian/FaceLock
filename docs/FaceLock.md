# 如何检测目前处在输入密码界面

* 密码输入界面有三种方式可以进入：
    * 从解锁中进入（手动锁屏）
        * ~~系统会识别为锁屏，但是不知道具体是哪种状态，需要排除睡眠和屏保~~
        * ~~进入睡眠和屏保时会设定一个状态变量，检查这个变量即可~~
        * 这种情况认为用户并不想立即解锁，忽略即可
    * 从睡眠中退出
        * 判断当前是否锁定，如果没有锁定就可以尝试解锁
    * 从屏保中退出
        * 只要处于屏保状态中有任何键盘或者鼠标操作
* 状态变化时需要进行的操作
    * com.apple.screensaver.didstart
        * 设定屏保状态变量
        * 监测键盘敲击和鼠标移动，有的话就判断当前是否锁定，没有锁定的话就**尝试解锁**
    * com.apple.screensaver.didstop
        * 暂无
    * com.apple.screenIsLocked
        * ~~检查睡眠和屏保状态变量，如果都不是则**尝试解锁**~~
    * com.apple.screenIsUnlocked
        * 取消睡眠和屏保状态变量
        * 停止监测键盘敲击和鼠标移动
    * screensDidSleepNotification
        * 停止监测键盘敲击和鼠标移动
        * 设定睡眠状态变量
        * 取消屏保状态变量
    * screensDidWakeNotification
        * 判断当前是否锁定，如果锁定的话就**尝试解锁**



# 方法

整个程序分为两个部分，逻辑部分和算法部分：逻辑部分负责用户设置和系统状态监测；算法部分负责人脸检测和人脸验证，使用 MTCNN + NCNN

* 逻辑部分（Swift）
    * 主要流程
        * 点击图标打开后以 menubar app 的形式常驻后台，监测系统状态，加载模型进入内存
        * 进入密码输入页面后每隔 1 秒调用算法部分，屏幕睡眠或者已经解锁则停止调用
        * 如果人脸验证成功则解锁屏幕
    * 添加人脸
        * 调用摄像头拍摄或者选择文件
        * 获取人脸图像后调用 C++ 函数提取特征
        * 对于无法检测到人脸到图片主动弹窗报错
        * 将特征本地存储
    * 验证人脸
        * 检查本地是否存储有特征，没有就直接结束
        * 有特征就调用摄像头拍摄一张照片，如果没有检测到人脸就直接退出
        * 检测到人脸就提取特征计算相似度，返回相似度
        * 相似度大于阈值则认为验证成功
* 算法部分（C++）
    * 进行人脸检测，检测不到人脸或者人脸面积小于阈值则直接返回
    * 如果检测到的人脸大于阈值则提取人脸特征，与预存的人脸特征比对，如果得到的相似度超过阈值则返回成功结果
    * 函数的输入是特征，函数自己调用摄像头拍摄图片，返回一个 float 相似度