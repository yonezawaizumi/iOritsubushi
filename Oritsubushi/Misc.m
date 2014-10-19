//
//  Misc.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/01.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "Misc.h"

// 内容が壊れることあり？？(?_?) キャッシュ中止
// static NSDateFormatter *dateFormatter;

@implementation Misc

+ (NSString *)URLEncode:(NSString *)rawURL
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)rawURL, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
}

+ (NSInteger)today
{
    /*if(!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyyMMdd";
    }*/
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    return [[dateFormatter stringFromDate:[NSDate date]] intValue];
}

@end
