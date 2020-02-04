//
//  CV.m
//  FaceLockProject
//
//  Created by 姚中天 on 2020/2/3.
//  Copyright © 2020 zh0ngtian. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#pragma clang diagnostic pop
#import <vector>

#import <Cocoa/Cocoa.h>
#import "CV.h"
#import "mtcnn_mobilefacenet.hpp"

static void NSImageToMat(NSImage *image, cv::Mat &mat) {
    // Create a pixel buffer.
    NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData:image.TIFFRepresentation];
    NSInteger width = bitmapImageRep.pixelsWide;
    NSInteger height = bitmapImageRep.pixelsHigh;
    CGImageRef imageRef = bitmapImageRep.CGImage;
    cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);

    // Draw all pixels to the buffer.
    cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
    cv::cvtColor(mat8uc4, mat8uc3, cv::COLOR_RGBA2BGR);

    mat = mat8uc3;
}

/*
static NSImage *MatToNSImage(cv::Mat &mat) {
    // Create a pixel buffer.
    assert(mat.elemSize() == 1 || mat.elemSize() == 3);
    cv::Mat matrgb;
    if (mat.elemSize() == 1) {
        cv::cvtColor(mat, matrgb, cv::COLOR_GRAY2RGB);
    } else if (mat.elemSize() == 3) {
        cv::cvtColor(mat, matrgb, cv::COLOR_BGR2RGB);
    }

    // Change a image format.
    NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
    CGColorSpaceRef colorSpace;
    if (matrgb.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    NSImage *image = [NSImage new];
    [image addRepresentation:bitmapImageRep];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return image;
}
 */

static std::vector<float> NSMutableArrayToVector(NSMutableArray *nsArray) {
    int len = int([nsArray count]);
    std::vector<float> vec(len);
    for (int i = 0; i < len; ++i) {
        vec[i] = [[nsArray objectAtIndex:i] floatValue];
    }
    return vec;
}

static NSMutableArray *VectorToNSMutableArray(std::vector<float> vec) {
    size_t len = vec.size();
    NSMutableArray *res = [NSMutableArray arrayWithCapacity:len];
    for (int i = 0; i < len; ++i) {
        NSNumber *number = [NSNumber numberWithFloat:vec[i]];
        [res addObject:number];
    }
    return res;
}

@implementation CV

+ (NSMutableArray *)getFea: (NSImage *)image withMinFace: (int)minFace {
    cv::Mat matImage;
    NSImageToMat(image, matImage);
    std::vector<float> fea = GetFea(matImage, minFace);
    NSMutableArray *res = VectorToNSMutableArray(fea);
    return res;
}

@end
