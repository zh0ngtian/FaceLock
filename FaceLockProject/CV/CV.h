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

@interface CV : NSObject
//+ (NSMutableArray *)getFea: (NSImage *)image withMinFace: (int)minFace;
+ (NSMutableArray *)getFea: (NSImage *)image withMinFace: (int)minFace;
@end

#endif /* CV_h */
