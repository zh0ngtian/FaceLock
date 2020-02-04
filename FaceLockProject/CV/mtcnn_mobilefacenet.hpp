//
//  mtcnn_mobilefacenet.hpp
//  FaceLockProject
//
//  Created by 姚中天 on 2020/2/2.
//  Copyright © 2020 MRP. All rights reserved.
//

#ifndef mtcnn_mobilefacenet_hpp
#define mtcnn_mobilefacenet_hpp

#include "mtcnn.h"
#include "mobilefacenet.h"
#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>

std::vector<float> GetFea(cv::Mat image, int min_face);

#endif /* mtcnn_mobilefacenet_hpp */
