//
//  Misc.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/01.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>

#define countof(ary) (sizeof (ary) / sizeof (ary)[0])

@interface Misc : NSObject

+ (NSString *)URLEncode:(NSString *)rawURL;
+ (NSInteger)today;

@end
