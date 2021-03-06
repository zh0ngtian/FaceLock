//
//  mtcnn_mobilefacenet.cpp
//  FaceLock
//
//  Created by 姚中天 on 2020/2/2.
//  Copyright © 2020 MRP. All rights reserved.
//

#include "mtcnn_mobilefacenet.h"

Recognizer::Recognizer(std::string model_path, int min_face) {
    if (min_face == 999) return;
    mtcnn_ptr_ = make_shared<MTCNN>(model_path);
    mtcnn_ptr_->SetMinFace(min_face);
    recognize_ptr_ = make_shared<Recognize>(model_path);
    std::cout << "Load model succeeded." << std::endl;
}

std::vector<float> Recognizer::GetFea(cv::Mat image) {
    clock_t start_time = clock();

    ncnn::Mat ncnn_img = ncnn::Mat::from_pixels(image.data, ncnn::Mat::PIXEL_BGR2RGB, image.cols, image.rows);
    std::vector<Bbox> final_bbox;

    mtcnn_ptr_->detectMaxFace(ncnn_img, final_bbox);
    
    clock_t mid_time = clock();
    double detect_time = (double)(mid_time - start_time) / CLOCKS_PER_SEC;
    std::cout << "detection time " << detect_time * 1000 << "ms" << std::endl;
    
    const int num_box = int(final_bbox.size());
    std::vector<cv::Rect> bbox;
    bbox.resize(num_box);

    std::vector<float> sample_fea;

    if (num_box == 1) {
        cv::Mat ROI(image, cv::Rect(final_bbox[0].x1, final_bbox[0].y1, final_bbox[0].x2 - final_bbox[0].x1 + 1, final_bbox[0].y2 - final_bbox[0].y1 + 1));
        cv::Mat cropped_img;
        ROI.copyTo(cropped_img);
        recognize_ptr_->start(cropped_img, sample_fea);
    }

    clock_t finish_time = clock();
    double total_time = (double)(finish_time - mid_time) / CLOCKS_PER_SEC;
    std::cout << "recognization time " << total_time * 1000 << "ms" << std::endl;

    return sample_fea;
}

float Recognizer::Verify(cv::Mat image, std::vector<float> target_fea) {
    std::vector<float> sample_fea = GetFea(image);
    float similarity = 0.0;
    if (sample_fea.size() != 0)
        similarity = calculSimilar(sample_fea, target_fea);
    return similarity;
}
