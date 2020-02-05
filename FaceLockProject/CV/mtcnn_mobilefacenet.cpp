//
//  mtcnn_mobilefacenet.cpp
//  FaceLockProject
//
//  Created by 姚中天 on 2020/2/2.
//  Copyright © 2020 MRP. All rights reserved.
//

#include "mtcnn_mobilefacenet.h"

/*
std::vector<float> GetFea(cv::Mat image, int min_face) {
    MTCNN mtcnn("models");
    mtcnn.SetMinFace(min_face);

    clock_t start_time = clock();

    ncnn::Mat ncnn_img = ncnn::Mat::from_pixels(image.data, ncnn::Mat::PIXEL_BGR2RGB, image.cols, image.rows);
    std::vector<Bbox> final_bbox;

    mtcnn.detectMaxFace(ncnn_img, final_bbox);

    const int num_box = int(final_bbox.size());
    std::vector<cv::Rect> bbox;
    bbox.resize(num_box);

    std::vector<float> sample_fea;

    if (num_box == 1) {
        cv::Mat ROI(image, cv::Rect(final_bbox[0].x1, final_bbox[0].y1, final_bbox[0].x2 - final_bbox[0].x1 + 1, final_bbox[0].y2 - final_bbox[0].y1 + 1));
        cv::Mat cropped_img;
        ROI.copyTo(cropped_img);

        Recognize recognize("models");
        imshow("cropped_img", cropped_img);
        cv::waitKey(0);
        recognize.start(cropped_img, sample_fea);
    } else {
        std::cout << "no face detected" << std::endl;
    }

    clock_t finish_time = clock();
    double total_time = (double)(finish_time - start_time) / CLOCKS_PER_SEC;
    std::cout << "time " << total_time * 1000 << "ms" << std::endl;

    return sample_fea;
}
 */

Recognizer::Recognizer(std::string model_path, int min_face) {
    if (min_face == 999) return;
    mtcnn_ptr_ = make_shared<MTCNN>(model_path);
    mtcnn_ptr_->SetMinFace(min_face);
    recognize_ptr_ = make_shared<Recognize>(model_path);
    std::cout << "Load model succeeded!" << std::endl;
}

std::vector<float> Recognizer::GetFea(cv::Mat image) {
    clock_t start_time = clock();

    ncnn::Mat ncnn_img = ncnn::Mat::from_pixels(image.data, ncnn::Mat::PIXEL_BGR2RGB, image.cols, image.rows);
    std::vector<Bbox> final_bbox;

    mtcnn_ptr_->detectMaxFace(ncnn_img, final_bbox);

    const int num_box = int(final_bbox.size());
    std::vector<cv::Rect> bbox;
    bbox.resize(num_box);

    std::vector<float> sample_fea;

    if (num_box == 1) {
        cv::Mat ROI(image, cv::Rect(final_bbox[0].x1, final_bbox[0].y1, final_bbox[0].x2 - final_bbox[0].x1 + 1, final_bbox[0].y2 - final_bbox[0].y1 + 1));
        cv::Mat cropped_img;
        ROI.copyTo(cropped_img);
        recognize_ptr_->start(cropped_img, sample_fea);
    } else {
        std::cout << "no face detected" << std::endl;
    }

    clock_t finish_time = clock();
    double total_time = (double)(finish_time - start_time) / CLOCKS_PER_SEC;
    std::cout << "time " << total_time * 1000 << "ms" << std::endl;

    return sample_fea;
}

float Recognizer::Verify(cv::Mat image, std::vector<float> target_fea) {
    std::vector<float> sample_fea = GetFea(image);
    float similarity = calculSimilar(sample_fea, target_fea);
    return similarity;
}
