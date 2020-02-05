//
//  CV.h
//  FaceLockProject
//
//  Created by 姚中天 on 2020/2/3.
//  Copyright © 2020 zh0ngtian. All rights reserved.
//

#ifndef CV_h
#define CV_h

#import <Foundation/Foundation.h>

struct CPPWrapper;

@interface CV : NSObject {
    struct CPPWrapper *_cppWrapper;
}
- (instancetype)initWithModelPath: (NSString *) modelPath minFace: (int) minFace;
- (NSMutableArray *)getFea: (NSImage *)image;
- (float)verify: (NSImage *)image withTargetFea: (NSMutableArray *) targetFea;
@end

#endif /* CV_h */
