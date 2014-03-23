//
//  NSString+CountSubstrings.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/14.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "NSString+CountSubstrings.h"

@implementation NSString (CountSubstrings)

- (NSUInteger)countSubstrings:(NSString *)substring
{
    NSUInteger count = 0;
    NSUInteger length = [self length];
    NSRange range = NSMakeRange(0, length); 
    while(range.location != NSNotFound) {
        range = [self rangeOfString:substring options:0 range:range];
        if(range.location != NSNotFound) {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            ++count; 
        }
    }
    return count;
}

@end
