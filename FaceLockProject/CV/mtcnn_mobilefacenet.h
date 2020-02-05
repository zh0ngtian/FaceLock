//
//  mtcnn_mobilefacenet.hpp
//  FaceLockProject
//
//  Created by 姚中天 on 2020/2/2.
//  Copyright © 2020 MRP. All rights reserved.
//

#ifndef mtcnn_mobilefacenet_h
#define mtcnn_mobilefacenet_h

#include "3rdparty/mtcnn.h"
#include "3rdparty/mobilefacenet.h"
#include <opencv2/opencv.hpp>
#include <memory>

class Recognizer {
public:
    Recognizer(std::string model_path = ".", int min_face = 999);
    std::vector<float> GetFea(cv::Mat image);
    float Verify(cv::Mat image, std::vector<float> target_fea);
private:
    std::shared_ptr<MTCNN> mtcnn_ptr_;
    std::shared_ptr<Recognize> recognize_ptr_;
};

#endif /* mtcnn_mobilefacenet_h */
